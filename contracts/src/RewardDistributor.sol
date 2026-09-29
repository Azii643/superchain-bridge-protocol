// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title RewardDistributor
/// @notice Distributes staking rewards and protocol incentives to ecosystem participants
contract RewardDistributor is Ownable {
    /// @notice Staker record
    struct Staker {
        uint256 stakedAmount;
        uint256 stakingStartDate;
        uint256 lastClaimDate;
        uint256 totalRewardsClaimed;
    }

    /// @notice Reward pool configuration
    struct RewardPool {
        string name;
        uint256 totalRewards;
        uint256 claimed;
        uint256 apy; // annual percentage yield (e.g., 1200 = 12%)
        bool active;
    }

    IERC20 public bridgeToken;
    
    mapping(address => Staker) public stakers;
    mapping(uint256 => RewardPool) public rewardPools;
    uint256 public nextPoolId = 1;
    
    uint256 public totalStaked;
    uint256 public totalRewardsDistributed;

    /// @notice Emitted when tokens are staked
    event Staked(address indexed user, uint256 amount, uint256 stakingStartDate);
    /// @notice Emitted when tokens are unstaked
    event Unstaked(address indexed user, uint256 amount, uint256 rewards);
    /// @notice Emitted when rewards are claimed
    event RewardsClaimed(address indexed user, uint256 amount);
    /// @notice Emitted when a reward pool is created
    event PoolCreated(uint256 indexed poolId, string name, uint256 apy);

    constructor(address _bridgeToken) Ownable(msg.sender) {
        bridgeToken = IERC20(_bridgeToken);
        
        // Initialize default reward pool
        createRewardPool("Staking Rewards", 25_000_000 * 10 ** 18, 1200); // 12% APY
    }

    /// @notice Create a new reward pool
    /// @param name pool name
    /// @param totalRewards total tokens available
    /// @param apy annual percentage yield
    function createRewardPool(string memory name, uint256 totalRewards, uint256 apy) 
        public 
        onlyOwner 
    {
        rewardPools[nextPoolId] = RewardPool({
            name: name,
            totalRewards: totalRewards,
            claimed: 0,
            apy: apy,
            active: true
        });
        emit PoolCreated(nextPoolId, name, apy);
        nextPoolId++;
    }

    /// @notice Stake tokens
    /// @param amount tokens to stake
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(
            bridgeToken.transferFrom(msg.sender, address(this), amount),
            "Stake transfer failed"
        );

        if (stakers[msg.sender].stakedAmount == 0) {
            stakers[msg.sender] = Staker({
                stakedAmount: amount,
                stakingStartDate: block.timestamp,
                lastClaimDate: block.timestamp,
                totalRewardsClaimed: 0
            });
        } else {
            stakers[msg.sender].stakedAmount += amount;
        }

        totalStaked += amount;
        emit Staked(msg.sender, amount, stakers[msg.sender].stakingStartDate);
    }

    /// @notice Calculate staking rewards for a user
    /// @param user address to calculate rewards for
    /// @param poolId reward pool to use
    function calculateRewards(address user, uint256 poolId) public view returns (uint256) {
        Staker memory staker = stakers[user];
        RewardPool memory pool = rewardPools[poolId];
        
        if (staker.stakedAmount == 0) return 0;
        if (!pool.active) return 0;

        uint256 stakingDuration = block.timestamp - staker.stakingStartDate;
        uint256 annualReward = (staker.stakedAmount * pool.apy) / 10_000;
        uint256 reward = (annualReward * stakingDuration) / 365 days;
        
        // Ensure reward doesn't exceed pool
        uint256 availableRewards = pool.totalRewards - pool.claimed;
        return reward > availableRewards ? availableRewards : reward;
    }

    /// @notice Claim staking rewards
    /// @param poolId reward pool to claim from
    function claimRewards(uint256 poolId) external {
        require(stakers[msg.sender].stakedAmount > 0, "No stake found");
        require(rewardPools[poolId].active, "Pool not active");

        uint256 rewards = calculateRewards(msg.sender, poolId);
        require(rewards > 0, "No rewards to claim");

        RewardPool storage pool = rewardPools[poolId];
        require(pool.claimed + rewards <= pool.totalRewards, "Insufficient pool balance");

        pool.claimed += rewards;
        stakers[msg.sender].lastClaimDate = block.timestamp;
        stakers[msg.sender].totalRewardsClaimed += rewards;
        totalRewardsDistributed += rewards;

        require(bridgeToken.transfer(msg.sender, rewards), "Reward transfer failed");
        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice Unstake tokens and claim final rewards
    /// @param amount tokens to unstake
    function unstake(uint256 amount) external {
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedAmount >= amount, "Insufficient staked amount");

        // Claim any pending rewards from default pool
        uint256 rewards = calculateRewards(msg.sender, 1);
        if (rewards > 0) {
            RewardPool storage pool = rewardPools[1];
            if (pool.claimed + rewards <= pool.totalRewards) {
                pool.claimed += rewards;
                staker.totalRewardsClaimed += rewards;
                totalRewardsDistributed += rewards;
            }
        }

        staker.stakedAmount -= amount;
        totalStaked -= amount;

        uint256 totalTransfer = amount + rewards;
        require(
            bridgeToken.transfer(msg.sender, totalTransfer),
            "Unstake transfer failed"
        );

        emit Unstaked(msg.sender, amount, rewards);
    }

    /// @notice Get staker information
    /// @param user address to query
    function getStaker(address user) external view returns (Staker memory) {
        return stakers[user];
    }

    /// @notice Get reward pool information
    /// @param poolId pool to query
    function getRewardPool(uint256 poolId) external view returns (RewardPool memory) {
        return rewardPools[poolId];
    }
}
