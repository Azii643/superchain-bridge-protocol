// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {ProtocolToken} from "../src/ProtocolToken.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {BridgeRouter} from "../src/BridgeRouter.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address treasury = vm.envAddress("TREASURY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy ProtocolToken
        ProtocolToken token = new ProtocolToken(msg.sender, treasury);
        console.log("ProtocolToken deployed at:", address(token));

        // Deploy SubscriptionManager
        SubscriptionManager subscriptionManager = new SubscriptionManager(
            address(token),
            treasury
        );
        console.log("SubscriptionManager deployed at:", address(subscriptionManager));

        // Deploy BridgeRouter
        BridgeRouter bridgeRouter = new BridgeRouter(address(subscriptionManager));
        console.log("BridgeRouter deployed at:", address(bridgeRouter));

        // Deploy RewardDistributor
        RewardDistributor rewardDistributor = new RewardDistributor(address(token));
        console.log("RewardDistributor deployed at:", address(rewardDistributor));

        // Allocate staking rewards
        token.allocateStakingRewards(25_000_000 * 10 ** 18);
        console.log("Allocated staking rewards");

        vm.stopBroadcast();
    }
}
