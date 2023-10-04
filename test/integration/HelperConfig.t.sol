//SPDX-License-Identifier:MIT

import {Test} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {console} from "../../lib/forge-std/src/console.sol";

pragma solidity 0.8.19;

contract TestHelperConfig is Test {
    HelperConfig helperConfig;

    function testSepoliaNetworkConfigReturnsIntendedValue() external {
        
        HelperConfig.NetworkConfig memory testData = HelperConfig.NetworkConfig({
            lotteryFee: 0.01 ether,
            interval: 30 seconds,
            vrfcoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 5453,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });


        vm.chainId(11155111);
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory result = helperConfig.getActiveNetworkConfig();


        assert(testData.lotteryFee == result.lotteryFee);
        assert(testData.interval == result.interval);
        assert(testData.vrfcoordinator == result.vrfcoordinator);
        assert(testData.keyHash == result.keyHash);
        assert(testData.subscriptionId == result.subscriptionId);
        assert(testData.callbackGasLimit == result.callbackGasLimit);
        assert(testData.link == result.link);
        assert(testData.deployerKey == result.deployerKey);

    }

    function testAnvilNetworkConfigReturnsIntendedValue() external {
      
        HelperConfig.NetworkConfig memory testData = HelperConfig.NetworkConfig({
            lotteryFee: 0.01 ether,
            interval: 30 seconds,
            vrfcoordinator: 0x5FbDB2315678afecb367f032d93F642f64180aa3,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            link: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512,
            deployerKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        });

        vm.chainId(31337);
        helperConfig = new HelperConfig();
      
        HelperConfig.NetworkConfig memory result = helperConfig.getActiveNetworkConfig();

        assert(testData.lotteryFee == result.lotteryFee);
        assert(testData.interval == result.interval);
        assert(testData.vrfcoordinator == result.vrfcoordinator);
        assert(testData.keyHash == result.keyHash);
        assert(testData.subscriptionId == result.subscriptionId);
        assert(testData.callbackGasLimit == result.callbackGasLimit);
        assert(testData.link == result.link);
        assert(testData.deployerKey == result.deployerKey);
    }
}
