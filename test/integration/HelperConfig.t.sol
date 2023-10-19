//SPDX-License-Identifier:MIT

import {Test} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

pragma solidity 0.8.19;

contract TestHelperConfig is Test {
    HelperConfig helperConfig;

    struct NetworkConfig {
        uint256 lotteryFee;
        uint256 interval;
        address vrfcoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    NetworkConfig sepoliaTestData = NetworkConfig({
        lotteryFee: 0.01 ether,
        interval: 30 seconds,
        vrfcoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
        keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
        subscriptionId: 5453,
        callbackGasLimit: 500000,
        link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
        deployerKey: vm.envUint("PRIVATE_KEY")
    });

    NetworkConfig anvilTestData = NetworkConfig({
        lotteryFee: 0.01 ether,
        interval: 30 seconds,
        vrfcoordinator: 0x5FbDB2315678afecb367f032d93F642f64180aa3,
        keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
        subscriptionId: 0,
        callbackGasLimit: 500000,
        link: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512,
        deployerKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    });

    function testSepoliaNetworkConfigReturnsIntendedValue() external {
        vm.chainId(11155111);
        helperConfig = new HelperConfig();
        (
            uint256 lotteryFee,
            uint256 interval,
            address vrfcoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.getActiveNetworkConfig();

        assert(sepoliaTestData.lotteryFee == lotteryFee);
        assert(sepoliaTestData.interval == interval);
        assert(sepoliaTestData.vrfcoordinator == vrfcoordinator);
        assert(sepoliaTestData.keyHash == keyHash);
        assert(sepoliaTestData.subscriptionId == subscriptionId);
        assert(sepoliaTestData.callbackGasLimit == callbackGasLimit);
        assert(sepoliaTestData.link == link);
        assert(sepoliaTestData.deployerKey == deployerKey);
    }

    function testAnvilNetworkConfigReturnsIntendedValue() external {
        vm.chainId(31337);
        helperConfig = new HelperConfig();

        (
            uint256 lotteryFee,
            uint256 interval,
            address vrfcoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.getActiveNetworkConfig();

        assert(anvilTestData.lotteryFee == lotteryFee);
        assert(anvilTestData.interval == interval);
        assert(anvilTestData.vrfcoordinator == vrfcoordinator);
        assert(anvilTestData.keyHash == keyHash);
        assert(anvilTestData.subscriptionId == subscriptionId);
        assert(anvilTestData.callbackGasLimit == callbackGasLimit);
        assert(anvilTestData.link == link);
        assert(anvilTestData.deployerKey == deployerKey);
    }
}
