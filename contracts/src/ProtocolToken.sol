// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title ProtocolToken
/// @notice BRIDGE token for governance, staking, and fee utility on Superchain Bridge Protocol
contract ProtocolToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    /// @notice Emitted when tokens are minted for ecosystem purposes
    event MintedForEcosystem(address indexed to, uint256 amount, string purpose);
    /// @notice Emitted when staking rewards are distributed
    event RewardDistributed(address indexed to, uint256 amount);

    /// @notice Treasury address that receives protocol revenue
    address public treasury;
    /// @notice Staking rewards pool
    uint256 public stakingRewards;
    /// @notice Total tokens minted for ecosystem incentives
    uint256 public ecosystemMinted;

    constructor(address initialOwner, address _treasury) 
        ERC20("Superchain Bridge", "BRIDGE") 
        Ownable(initialOwner) 
        ERC20Permit("Superchain Bridge")
    {
        treasury = _treasury;
        // Initial supply: 1 billion tokens
        _mint(initialOwner, 1_000_000_000 * 10 ** 18);
    }

    /// @notice Mint tokens for ecosystem purposes (governance controlled)
    /// @param to recipient address
    /// @param amount tokens to mint
    /// @param purpose descriptive reason for mint
    function mintForEcosystem(address to, uint256 amount, string calldata purpose) 
        external 
        onlyOwner 
    {
        ecosystemMinted += amount;
        _mint(to, amount);
        emit MintedForEcosystem(to, amount, purpose);
    }

    /// @notice Distribute staking rewards
    /// @param to staker address
    /// @param amount reward amount
    function distributeReward(address to, uint256 amount) 
        external 
        onlyOwner 
    {
        require(amount <= stakingRewards, "Insufficient staking rewards");
        stakingRewards -= amount;
        _mint(to, amount);
        emit RewardDistributed(to, amount);
    }

    /// @notice Allocate tokens to the staking rewards pool
    /// @param amount tokens to allocate
    function allocateStakingRewards(uint256 amount) 
        external 
        onlyOwner 
    {
        stakingRewards += amount;
    }

    /// @notice Update treasury address
    /// @param newTreasury new treasury address
    function setTreasury(address newTreasury) 
        external 
        onlyOwner 
    {
        require(newTreasury != address(0), "Invalid treasury");
        treasury = newTreasury;
    }

    /// @notice Governance: withdraw treasury funds
    /// @param amount tokens to withdraw
    function withdrawFromTreasury(uint256 amount) 
        external 
        onlyOwner 
    {
        require(balanceOf(treasury) >= amount, "Insufficient treasury balance");
        // Transfer from treasury to owner (governance can decide destination)
        transferFrom(treasury, msg.sender, amount);
    }
}
