//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 lotteryFee;
        uint256 interval;
        address vrfcoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = sepoliaNetworkConfig();
        } else {
            activeNetworkConfig = anvilNetworkConfig();
        }
    }

    function sepoliaNetworkConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            lotteryFee: 0.01 ether,
            interval: 30 seconds,
            vrfcoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 5598,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function anvilNetworkConfig() internal returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfcoordinator != address(0)) {
            return activeNetworkConfig;
        } else {
            uint96 baseFee = 0.25 ether; // 0.25 Link
            uint96 gasPriceLink = 1e9; //1 gwei of link
            vm.startBroadcast();
            VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee,gasPriceLink);
            LinkToken linkToken = new LinkToken();
            vm.stopBroadcast();

            return NetworkConfig({
                lotteryFee: 0.01 ether,
                interval: 30 seconds,
                vrfcoordinator: address(vrfCoordinatorV2Mock),
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, //our script will add this
                callbackGasLimit: 500000,
                link: address(linkToken)
            });
        }
    }
}
