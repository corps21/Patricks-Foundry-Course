// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface} from "../lib/chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "../lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {
    error Lottery__notEnoughEthSend();
    error Lottery__notAvailableYet();
    error Lottery__transferFailed();
    error Lottery__UpkeepNotNeeded();

    enum LotteryState {
        OPEN,
        CALCULATING
    }

    uint16 constant REQUEST_CONFIRMATION = 3;
    uint32 constant NUM_WORDS = 1;

    uint32 immutable i_callbackGasLimit;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_keyHash;
    uint256 private immutable i_lotteryFee;
    /**
     * @dev duration of lottery in seconds
     */
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface immutable i_vrfcoordinator;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    LotteryState private s_lotteryState;
    address private s_recentWinner;

    /**
     * Events
     */
    event EnteredLottery(address indexed);
    event WinnerPicked(address indexed);
    event RequestedLotteryWinner(uint256 indexed);

    constructor(
        uint256 _lotteryFee,
        uint256 _interval,
        address _vrfcoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfcoordinator) {
        i_lotteryFee = _lotteryFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfcoordinator = VRFCoordinatorV2Interface(_vrfcoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
    }

    function enterLottery() external payable {
        if (msg.value != i_lotteryFee) {
            revert Lottery__notEnoughEthSend();
        }
        s_players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    function checkUpkeep(bytes memory)
        /**
         * checkdata
         */
        public
        view
        returns (bool upkeepNeeded, bytes memory)
    /**
     * performData
     */
    {
        /**
         * @dev Condition to meet
         *         i. The interval limit is passed
         *         ii. lottery is in open state
         *         iii.lottery contract have non zero balance
         *         iv. non zero players have entered the lottery
         */

        bool timeLimitPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool isOpen = s_lotteryState == LotteryState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeLimitPassed && isOpen && hasBalance && hasPlayers;

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded();
        }
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfcoordinator.requestRandomWords(
            i_keyHash, i_subscriptionId, REQUEST_CONFIRMATION, i_callbackGasLimit, NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256,
        /**
         * _requestId
         */
        uint256[] memory _randomWords
    ) internal override {
        uint256 lengthOfList = s_players.length;
        address winner = s_players[_randomWords[0] % lengthOfList];
        emit WinnerPicked(winner);

        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[] (0);

        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__transferFailed();
        }
    }

    /**
     * Getter Functions
     */

    function getFeePrice() external view returns (uint256) {
        return i_lotteryFee;
    }

    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    function getListOfPlayers(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns(uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }
}
