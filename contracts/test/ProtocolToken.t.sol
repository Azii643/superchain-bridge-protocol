// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {ProtocolToken} from "../src/ProtocolToken.sol";

contract ProtocolTokenTest is Test {
    ProtocolToken public token;
    address public owner;
    address public treasury;
    address public user;

    function setUp() public {
        owner = address(this);
        treasury = address(0x1);
        user = address(0x2);

        token = new ProtocolToken(owner, treasury);
    }

    function test_InitialSupply() public view {
        assertEq(token.balanceOf(owner), 1_000_000_000 * 10 ** 18);
    }

    function test_MintForEcosystem() public {
        uint256 amount = 1_000_000 * 10 ** 18;
        token.mintForEcosystem(user, amount, "ecosystem_grants");
        assertEq(token.balanceOf(user), amount);
        assertEq(token.ecosystemMinted(), amount);
    }

    function test_AllocateStakingRewards() public {
        uint256 amount = 10_000_000 * 10 ** 18;
        token.allocateStakingRewards(amount);
        assertEq(token.stakingRewards(), amount);
    }

    function test_DistributeReward() public {
        token.allocateStakingRewards(100 * 10 ** 18);
        token.distributeReward(user, 50 * 10 ** 18);
        assertEq(token.balanceOf(user), 50 * 10 ** 18);
        assertEq(token.stakingRewards(), 50 * 10 ** 18);
    }

    function test_SetTreasury() public {
        address newTreasury = address(0x3);
        token.setTreasury(newTreasury);
        assertEq(token.treasury(), newTreasury);
    }
}
