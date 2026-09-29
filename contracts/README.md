# Contracts

This directory houses the smart contracts for the Superchain Bridge Protocol product layer.

## Planned contracts

- `BridgeRouter.sol` — message routing between chains
- `SubscriptionManager.sol` — plan access and recurring billing logic
- `ProtocolToken.sol` — governance / staking utility token
- `RewardDistributor.sol` — reward and treasury distribution
- `MessageVerifier.sol` — cross-chain validation helpers

## Current status

This starter repo currently contains the product structure and app shell. The Solidity layer is intentionally scaffolded for future build-out.

## Recommended future setup

```bash
forge init contracts
```

Then build the contract suite around the actual business logic required for the product rollout.
