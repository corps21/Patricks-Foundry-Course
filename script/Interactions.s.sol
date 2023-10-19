//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() internal returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();

        (,, address vrfcoordinator,,,,, uint256 deployerKey) = helperConfig.getActiveNetworkConfig();

        return createSubscriptionId(vrfcoordinator, deployerKey);
    }

    function createSubscriptionId(address vrfcoordinator, uint256 deployerKey) public returns (uint64) {
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock vrfCoo = VRFCoordinatorV2Mock(vrfcoordinator);
        uint64 SubId = vrfCoo.createSubscription();
        vm.stopBroadcast();
        return SubId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address _contractAddress) internal {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfcoordinator,, uint64 subscriptionId,,, uint256 deployerKey) =
            helperConfig.getActiveNetworkConfig();
        return addConsumer(_contractAddress, vrfcoordinator, subscriptionId, deployerKey);
    }

    function addConsumer(address _contractAddress, address vrfCoordinatorV2, uint64 subId, uint256 deployerKey)
        public
    {
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinatorV2).addConsumer(subId, _contractAddress);
        vm.stopBroadcast();
    }

    function run() external {
        address contractAddress = DevOpsTools.get_most_recent_deployment("lottery", block.chainid);
        addConsumerUsingConfig(contractAddress);
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfcoordinator,, uint64 subscriptionId,, address link, uint256 deployerKey) =
            helperConfig.getActiveNetworkConfig();
        return fundSubscription(vrfcoordinator, subscriptionId, link, deployerKey);
    }

    function fundSubscription(address vrfCoordinatorV2, uint64 subId, address link, uint256 deployerKey) public {
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinatorV2).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinatorV2, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
