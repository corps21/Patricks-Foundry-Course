//SPDX-License-Identifier:MIT

import {Test} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {console} from "../../lib/forge-std/src/console.sol";

pragma solidity 0.8.19;

contract TestHelperConfig is Test {
    HelperConfig helperConfig;

    uint256 lotteryFee;
    uint256 interval;
    address vrfcoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    uint256 deployerKey;



    function testSepoliaNetworkConfigReturnsIntendedValue() external {
        uint256 sepoliaLotteryFee = 0.01 ether;
        uint256 sepoliaInterval = 30 seconds;
        address sepoliaVrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
        bytes32 sepoliaKeyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        uint64 sepoliaSubscriptionId = 5453;
        uint32 sepoliaCallbackGasLimit = 500000;
        address sepoliaLinkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        uint256 sepoliaDeployerKey = vm.envUint("PRIVATE_KEY");



        vm.chainId(11155111);
        helperConfig = new HelperConfig();
        (lotteryFee,interval,vrfcoordinator,keyHash,subscriptionId,callbackGasLimit,link,deployerKey) = helperConfig.activeNetworkConfig();

        assert(lotteryFee == sepoliaLotteryFee);
        assert(interval == sepoliaInterval);
        assert(vrfcoordinator == sepoliaVrfCoordinator);
        assert(keyHash == sepoliaKeyHash);
        assert(subscriptionId == sepoliaSubscriptionId);
        assert(callbackGasLimit == sepoliaCallbackGasLimit);
        assert(link == sepoliaLinkAddress);
        assert(deployerKey == sepoliaDeployerKey);
    }

    function testAnvilNetworkConfigReturnsIntendedValue() external {
        uint256 anvilLotteryFee = 0.01 ether;
        uint256 anvilInterval = 30 seconds;
        address anvilVrfCoordinator = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        bytes32 anvilKeyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        uint64 anvilSubscriptionId = 0;
        uint32 anvilCallbackGasLimit = 500000;
        address anvilLinkAddress = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        uint256 DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;



        vm.chainId(31337);
        helperConfig = new HelperConfig();
        (lotteryFee,interval,vrfcoordinator,keyHash,subscriptionId,callbackGasLimit,link,deployerKey) = helperConfig.activeNetworkConfig();

        assert(lotteryFee == anvilLotteryFee);
        assert(interval == anvilInterval);
        assert(vrfcoordinator == anvilVrfCoordinator);
        assert(keyHash == anvilKeyHash);
        assert(subscriptionId == anvilSubscriptionId);
        assert(callbackGasLimit == anvilCallbackGasLimit);
        assert(link == anvilLinkAddress);
        assert(deployerKey == DEFAULT_ANVIL_KEY);
    }


}