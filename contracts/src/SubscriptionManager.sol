// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title SubscriptionManager
/// @notice Manages subscription tiers, usage limits, and access control for the protocol
contract SubscriptionManager is Ownable {
    /// @notice Subscription tier definition
    struct Tier {
        string name;
        uint256 monthlyPrice; // in BRIDGE tokens
        uint256 messageQuota; // messages allowed per month
        uint256 priorityLevel; // 1 = free, 2 = pro, 3 = enterprise
        bool active;
    }

    /// @notice User subscription record
    struct Subscription {
        uint256 tierId;
        uint256 renewalDate;
        uint256 messagesUsed;
        uint256 monthStartDate;
        bool active;
    }

    /// @notice Protocol statistics
    struct ProtocolStats {
        uint256 totalMessagesProcessed;
        uint256 totalUsersActive;
        uint256 monthlyRecurringRevenue; // in BRIDGE tokens
    }

    IERC20 public bridgeToken;
    address public treasury;
    uint256 public nextTierId = 1;
    
    mapping(uint256 => Tier) public tiers;
    mapping(address => Subscription) public subscriptions;
    mapping(address => uint256) public usageTracking; // messages this month
    mapping(uint256 => address[]) public tierSubscribers; // track by tier
    
    ProtocolStats public stats;

    /// @notice Emitted when a subscription is created or renewed
    event SubscriptionCreated(address indexed user, uint256 tierId, uint256 renewalDate);
    /// @notice Emitted when a message is recorded to usage
    event MessageRecorded(address indexed user, uint256 count);
    /// @notice Emitted when a tier is created or updated
    event TierUpdated(uint256 indexed tierId, string name, uint256 price, uint256 quota);
    /// @notice Emitted when protocol stats change
    event StatsUpdated(uint256 totalMessages, uint256 totalUsers, uint256 mrr);

    constructor(address _bridgeToken, address _treasury) Ownable(msg.sender) {
        bridgeToken = IERC20(_bridgeToken);
        treasury = _treasury;

        // Initialize default tiers
        createTier("Free", 0, 1000, 1);
        createTier("Pro", 49 * 10 ** 18, 100_000, 2); // 49 BRIDGE/month
        createTier("Enterprise", 999 * 10 ** 18, 1_000_000, 3); // custom but base price
    }

    /// @notice Create a new subscription tier
    /// @param _name tier name
    /// @param _price monthly price in BRIDGE tokens
    /// @param _quota message quota per month
    /// @param _priority priority level
    function createTier(string memory _name, uint256 _price, uint256 _quota, uint256 _priority) 
        public 
        onlyOwner 
    {
        tiers[nextTierId] = Tier({
            name: _name,
            monthlyPrice: _price,
            messageQuota: _quota,
            priorityLevel: _priority,
            active: true
        });
        emit TierUpdated(nextTierId, _name, _price, _quota);
        nextTierId++;
    }

    /// @notice Subscribe a user to a tier
    /// @param user address to subscribe
    /// @param tierId tier to subscribe to
    function subscribe(address user, uint256 tierId) external {
        require(tiers[tierId].active, "Tier not active");
        
        uint256 price = tiers[tierId].monthlyPrice;
        
        // Charge subscription fee if not free tier
        if (price > 0) {
            require(
                bridgeToken.transferFrom(user, treasury, price),
                "Payment failed"
            );
        }

        subscriptions[user] = Subscription({
            tierId: tierId,
            renewalDate: block.timestamp + 30 days,
            messagesUsed: 0,
            monthStartDate: block.timestamp,
            active: true
        });

        tierSubscribers[tierId].push(user);
        stats.totalUsersActive++;

        if (price > 0) {
            stats.monthlyRecurringRevenue += price;
        }

        emit SubscriptionCreated(user, tierId, subscriptions[user].renewalDate);
        emit StatsUpdated(stats.totalMessagesProcessed, stats.totalUsersActive, stats.monthlyRecurringRevenue);
    }

    /// @notice Record a message usage for a user
    /// @param user address using the service
    function recordMessage(address user) external onlyOwner {
        require(subscriptions[user].active, "Subscription not active");
        
        Subscription storage sub = subscriptions[user];
        Tier memory tier = tiers[sub.tierId];

        // Reset usage if month has passed
        if (block.timestamp >= sub.monthStartDate + 30 days) {
            sub.messagesUsed = 0;
            sub.monthStartDate = block.timestamp;
        }

        require(sub.messagesUsed < tier.messageQuota, "Message quota exceeded");
        sub.messagesUsed++;
        stats.totalMessagesProcessed++;

        emit MessageRecorded(user, sub.messagesUsed);
        emit StatsUpdated(stats.totalMessagesProcessed, stats.totalUsersActive, stats.monthlyRecurringRevenue);
    }

    /// @notice Check if user's subscription is active and within quota
    /// @param user address to check
    function canUseService(address user) external view returns (bool) {
        Subscription memory sub = subscriptions[user];
        if (!sub.active) return false;
        
        Tier memory tier = tiers[sub.tierId];
        return sub.messagesUsed < tier.messageQuota;
    }

    /// @notice Get current usage for a user
    /// @param user address to check
    function getUsage(address user) external view returns (uint256 used, uint256 quota) {
        Subscription memory sub = subscriptions[user];
        Tier memory tier = tiers[sub.tierId];
        return (sub.messagesUsed, tier.messageQuota);
    }

    /// @notice Update treasury address
    /// @param newTreasury new treasury address
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury");
        treasury = newTreasury;
    }

    /// @notice Get protocol stats
    function getStats() external view returns (ProtocolStats memory) {
        return stats;
    }
}
