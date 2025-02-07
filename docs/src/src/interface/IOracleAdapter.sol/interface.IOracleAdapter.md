# IOracleAdapter

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/IOracleAdapter.sol)

Oracle adapter interface for dai oracle

## Functions

### getPrice

Get the price of a token

The price is scaled by precision()

```solidity
function getPrice(address token) external view returns (uint256);
```

**Parameters**

| Name    | Type      | Description                   |
| ------- | --------- | ----------------------------- |
| `token` | `address` | The token to get the price of |

**Returns**

| Name     | Type      | Description            |
| -------- | --------- | ---------------------- |
| `<none>` | `uint256` | The price of the token |

### precision

Get the precision

```solidity
function precision() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                  |
| -------- | --------- | ---------------------------- |
| `<none>` | `uint256` | The precision equals to 1e18 |

## Events

### FallbackOracleChanged

```solidity
event FallbackOracleChanged(address oldFallbackOracle, address newFallbackOracle);
```

## Errors

### ZeroPrice

```solidity
error ZeroPrice();
```
