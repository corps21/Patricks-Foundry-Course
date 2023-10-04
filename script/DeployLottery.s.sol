//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Lottery} from "../src/Lottery.sol";
import {CreateSubscription} from "./Interactions.s.sol";
import {FundSubscription} from "./Interactions.s.sol";
import {AddConsumer} from "./Interactions.s.sol";

contract DeployLottery is Script {
    function run() external returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 lotteryFee,
            uint256 interval,
            address vrfcoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscriptionId(vrfcoordinator, deployerKey);
        }
        FundSubscription fundSubscriptions = new FundSubscription();
        fundSubscriptions.fundSubscription(vrfcoordinator, subscriptionId, link, deployerKey);

        vm.startBroadcast(deployerKey);
        Lottery lottery = new Lottery(
                lotteryFee,
                interval,
                vrfcoordinator,
                keyHash,
                subscriptionId,
                callbackGasLimit
            );
        vm.stopBroadcast();

        AddConsumer addConsumers = new AddConsumer();
        addConsumers.addConsumer(address(lottery), vrfcoordinator, subscriptionId, deployerKey);

        return (lottery, helperConfig);
    }
}
