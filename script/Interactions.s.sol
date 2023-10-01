//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";
import {console} from "../lib/forge-std/src/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() internal returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();

        (,, address vrfcoordinator,,,,) = helperConfig.activeNetworkConfig();

        return createSubscriptionId(vrfcoordinator);
    }

    function createSubscriptionId(address vrfcoordinator) public returns (uint64) {
        VRFCoordinatorV2Mock vrfCoo = VRFCoordinatorV2Mock(vrfcoordinator);
        uint64 result = vrfCoo.createSubscription();
        return result;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinatorV2,, uint64 subId,, address link) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinatorV2, subId, link);
    }

    function fundSubscription(address vrfCoordinatorV2, uint64 subId, address link) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinatorV2);
        console.log("On ChainID: ", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinatorV2).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(vrfCoordinatorV2, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function run() external {
        address contractAddress = DevOpsTools.get_most_recent_deployment("Lottery", block.chainid);
        addConsumerUsingConfig(contractAddress);
    }

    function addConsumerUsingConfig(address _contractAddress) internal {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinatorV2,, uint64 subId,,) = helperConfig.activeNetworkConfig();
        addConsumer(_contractAddress, vrfCoordinatorV2, subId);
    }

    function addConsumer(address _contractAddress, address vrfCoordinatorV2, uint64 subId) public {
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinatorV2).addConsumer(subId, _contractAddress);
        vm.stopBroadcast();
    }

}
