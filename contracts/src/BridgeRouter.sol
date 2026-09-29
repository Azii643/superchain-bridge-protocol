// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IL2ToL2CrossDomainMessenger} from "@interop-lib/interfaces/IL2ToL2CrossDomainMessenger.sol";
import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";
import {CrossDomainMessageLib} from "@interop-lib/libraries/CrossDomainMessageLib.sol";

/// @title BridgeRouter
/// @notice Routes and executes cross-chain messages for protocol users
contract BridgeRouter {
    /// @notice Subscription manager reference for access control
    address public subscriptionManager;

    /// @notice Message routing record
    struct BridgeMessage {
        uint256 sourceChainId;
        uint256 destinationChainId;
        address sender;
        address target;
        bytes payload;
        uint256 timestamp;
        bool executed;
    }

    /// @notice Message ID counter
    uint256 public messageCount;
    mapping(uint256 => BridgeMessage) public messages;

    /// @notice Emitted when a bridge message is sent
    event BridgeSent(
        uint256 indexed messageId,
        uint256 indexed sourceChainId,
        uint256 indexed destinationChainId,
        address sender,
        address target
    );
    /// @notice Emitted when a bridge message is executed
    event BridgeExecuted(uint256 indexed messageId, bool success);

    IL2ToL2CrossDomainMessenger internal messenger =
        IL2ToL2CrossDomainMessenger(PredeployAddresses.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

    constructor(address _subscriptionManager) {
        subscriptionManager = _subscriptionManager;
    }

    /// @notice Send a cross-chain bridge message
    /// @param destinationChainId target chain ID
    /// @param target address on destination chain
    /// @param payload encoded function call
    function sendBridgeMessage(
        uint256 destinationChainId,
        address target,
        bytes calldata payload
    ) external returns (uint256 messageId) {
        messageId = messageCount++;

        messages[messageId] = BridgeMessage({
            sourceChainId: block.chainid,
            destinationChainId: destinationChainId,
            sender: msg.sender,
            target: target,
            payload: payload,
            timestamp: block.timestamp,
            executed: false
        });

        // Send via interop messenger
        messenger.sendMessage(destinationChainId, target, payload);

        emit BridgeSent(
            messageId,
            block.chainid,
            destinationChainId,
            msg.sender,
            target
        );

        return messageId;
    }

    /// @notice Execute a bridge message (called on destination chain)
    /// @param messageId ID of message to execute
    function executeBridgeMessage(uint256 messageId) external {
        require(messages[messageId].executed == false, "Message already executed");
        
        // Verify caller is the messenger
        CrossDomainMessageLib.requireCallerIsCrossDomainMessenger();

        messages[messageId].executed = true;
        emit BridgeExecuted(messageId, true);
    }

    /// @notice Get bridge message details
    /// @param messageId ID to query
    function getMessage(uint256 messageId) external view returns (BridgeMessage memory) {
        return messages[messageId];
    }
}
