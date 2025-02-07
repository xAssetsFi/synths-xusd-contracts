# IDebtShares

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/IDebtShares.sol)

**Inherits:**
IERC20Metadata

## Functions

### mint

Mint debt shares

_only platforms can call this function_

```solidity
function mint(address to, uint256 amount) external;
```

**Parameters**

| Name     | Type      | Description                            |
| -------- | --------- | -------------------------------------- |
| `to`     | `address` | The address to mint the debt shares to |
| `amount` | `uint256` | The amount of debt shares to mint      |

### burn

Burn debt shares

_only platforms can call this function_

```solidity
function burn(address from, uint256 amount) external;
```

**Parameters**

| Name     | Type      | Description                              |
| -------- | --------- | ---------------------------------------- |
| `from`   | `address` | The address to burn the debt shares from |
| `amount` | `uint256` | The amount of debt shares to burn        |

### addReward

Notify the target reward amount

_only platforms and owner can call this function_

```solidity
function addReward(address token, uint256 amount) external;
```

**Parameters**

| Name     | Type      | Description                               |
| -------- | --------- | ----------------------------------------- |
| `token`  | `address` | The token to notify the reward amount for |
| `amount` | `uint256` | The amount of reward to notify            |

## Events

### RewardAdded

```solidity
event RewardAdded(address indexed token, uint256 amount);
```

### RewardPaid

```solidity
event RewardPaid(address indexed user, address indexed token, uint256 amount);
```

### NewRewardToken

```solidity
event NewRewardToken(address token);
```
