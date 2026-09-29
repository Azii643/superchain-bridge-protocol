// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {ProtocolToken} from "../src/ProtocolToken.sol";

contract SubscriptionManagerTest is Test {
    SubscriptionManager public manager;
    ProtocolToken public token;
    address public treasury;
    address public user;

    function setUp() public {
        treasury = address(0x1);
        user = address(0x2);

        token = new ProtocolToken(address(this), treasury);
        manager = new SubscriptionManager(address(token), treasury);

        // Transfer tokens to user for testing
        token.transfer(user, 10_000 * 10 ** 18);
    }

    function test_FreeTierSubscription() public {
        vm.prank(user);
        manager.subscribe(user, 1); // Free tier

        (uint256 used, uint256 quota) = manager.getUsage(user);
        assertEq(quota, 1000);
    }

    function test_ProTierSubscription() public {
        vm.startPrank(user);
        token.approve(address(manager), 49 * 10 ** 18);
        manager.subscribe(user, 2); // Pro tier
        vm.stopPrank();

        (uint256 used, uint256 quota) = manager.getUsage(user);
        assertEq(quota, 100_000);
    }

    function test_RecordMessage() public {
        vm.prank(user);
        manager.subscribe(user, 1);

        vm.prank(address(this)); // Only owner can record
        manager.recordMessage(user);

        (uint256 used, ) = manager.getUsage(user);
        assertEq(used, 1);
    }

    function test_CanUseService() public {
        vm.prank(user);
        manager.subscribe(user, 1);

        assertTrue(manager.canUseService(user));
    }
}
