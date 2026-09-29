// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";
import {ProtocolToken} from "../src/ProtocolToken.sol";

contract RewardDistributorTest is Test {
    RewardDistributor public distributor;
    ProtocolToken public token;
    address public staker;

    function setUp() public {
        staker = address(0x2);

        token = new ProtocolToken(address(this), address(0x1));
        distributor = new RewardDistributor(address(token));

        // Transfer tokens to staker
        token.transfer(staker, 100_000 * 10 ** 18);
    }

    function test_Stake() public {
        vm.startPrank(staker);
        token.approve(address(distributor), 1_000 * 10 ** 18);
        distributor.stake(1_000 * 10 ** 18);
        vm.stopPrank();

        vm.prank(staker);
        uint256 amount = token.balanceOf(staker);
        assertEq(amount, 99_000 * 10 ** 18);
    }

    function test_CalculateRewards() public {
        vm.startPrank(staker);
        token.approve(address(distributor), 1_000 * 10 ** 18);
        distributor.stake(1_000 * 10 ** 18);
        vm.stopPrank();

        // Simulate passage of time
        vm.warp(block.timestamp + 365 days);

        uint256 rewards = distributor.calculateRewards(staker, 1);
        // 12% APY on 1000 tokens = 120 tokens
        assertGt(rewards, 0);
    }

    function test_Unstake() public {
        vm.startPrank(staker);
        token.approve(address(distributor), 1_000 * 10 ** 18);
        distributor.stake(1_000 * 10 ** 18);
        
        vm.warp(block.timestamp + 365 days);
        
        distributor.unstake(1_000 * 10 ** 18);
        vm.stopPrank();

        // User should have initial amount + rewards
        uint256 finalBalance = token.balanceOf(staker);
        assertGt(finalBalance, 100_000 * 10 ** 18);
    }
}
