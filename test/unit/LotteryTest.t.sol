//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/Lottery.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {console} from "../../lib/forge-std/src/Script.sol";

contract LotteryTest is Test {
    /**
     * Events
     */
    event EnteredLottery(address indexed);

    Lottery lottery;
    HelperConfig helperConfig;

    uint256 lotteryFee;
    uint256 interval;
    address vrfcoordinator;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    address link;
    uint256 deployerKey;

    address public player = makeAddr("User");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant LOTTERY_FEE = 0.01 ether;

    function setUp() external {
        DeployLottery deployer = new DeployLottery();
        (lottery, helperConfig) = deployer.run();
        vm.deal(player, STARTING_USER_BALANCE);

        (lotteryFee, interval, vrfcoordinator, keyHash,, callbackGasLimit, link, deployerKey) =
            helperConfig.activeNetworkConfig();
    }

    function testLotteryStateIsOpen() external view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    function testfailsWhenNotEnoughEthIsSend() external {
        vm.expectRevert(Lottery.Lottery__notEnoughEthSend.selector); //keep in mind to learn more about selector
        lottery.enterLottery();
    }

    function testWhetherPlayersAreAdded() external {
        vm.startPrank(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
        vm.stopPrank();
        address playerFirst = lottery.getListOfPlayers(0);

        assert(playerFirst == player);
    }

    function testEventEmittedForEnteringLottery() external {
        vm.startPrank(player);
        vm.expectEmit(true, false, false, false, address(lottery));
        emit EnteredLottery(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
        vm.stopPrank();
    }

    function testfailsWhenLotteryStateIsInCalculating() external {
        vm.prank(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");

        uint256 lotteryState = uint256(lottery.getLotteryState());
        console.log("this is the lottery state: ", lotteryState);
        vm.expectRevert(Lottery.Lottery__notAvailableYet.selector);
        vm.prank(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
    }

    function testCheckUpKeepReturnsFalseForZeroBalance() external {
        vm.prank(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");
        

        (bool UpKeepNeeded,) = lottery.checkUpkeep("");

        assert(UpKeepNeeded == false);
    }

    function testCheckUpKeepReturnsFalseIfLotteryNotOpen() external {
        vm.prank(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");

        (bool UpKeepNeeded,) = lottery.checkUpkeep("");

        assert(!UpKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed() external {
        vm.prank(player);
        lottery.enterLottery{value: LOTTERY_FEE}(); //s_player.length > 0
        // address(lottery).balance > 0

        //lottery state is OPEN by default

        (bool UpKeepNeeded,) = lottery.checkUpkeep("");

        assert(!UpKeepNeeded);
    }

    function testCheckUpKeepReturnsTrueWhenParametersAreGood() external {
        vm.prank(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool UpKeepNeeded,) = lottery.checkUpkeep("");

        assert(UpKeepNeeded);
    }

    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() external {
        vm.prank(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        lottery.performUpkeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() external {
        vm.expectRevert(Lottery.Lottery__UpkeepNotNeeded.selector);
        lottery.performUpkeep("");
    }

    modifier LotteryEnteredAndTimePassed() {
        vm.prank(player);
        lottery.enterLottery{value: LOTTERY_FEE}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpKeepUpdatesLotteryStateAndEmitRequestId() external LotteryEnteredAndTimePassed {
        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Lottery.LotteryState rState = lottery.getLotteryState();
        assert(uint256(requestId) > 0);

        assert(rState == Lottery.LotteryState.CALCULATING);
    }

    modifier skipFork {
        if(block.chainid != 31337) {
            return;
        }
            _;
    }

    function testFulfillRandomWordsCanOnlyBePerformedAfterPerformUpKeep(uint256 randomRequestId)
        external
        LotteryEnteredAndTimePassed skipFork
    {
        vm.expectRevert("nonexistent request");

        VRFCoordinatorV2Mock(vrfcoordinator).fulfillRandomWords(randomRequestId, address(lottery));
    }

    function testFulfillRandomWordsPicksAWinnerAndResetsAndSendMoney() external LotteryEnteredAndTimePassed skipFork {
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address Player = address(uint160(i));
            hoax(Player, STARTING_USER_BALANCE);
            lottery.enterLottery{value: LOTTERY_FEE}();
        }

        uint256 price = LOTTERY_FEE * (additionalEntrants + 1);

        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        uint256 previousTimeStamp = lottery.getLastTimeStamp();

        VRFCoordinatorV2Mock(vrfcoordinator).fulfillRandomWords(uint256(requestId), address(lottery));

        assert(uint256(lottery.getLotteryState()) == 0);
        assert(lottery.getRecentWinner() != address(0));
        assert(lottery.getLengthOfPlayers() == 0);
        assert(lottery.getLastTimeStamp() > previousTimeStamp);
        assert(lottery.getRecentWinner().balance == STARTING_USER_BALANCE + price - LOTTERY_FEE);
    }
}
