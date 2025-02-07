# IPlatform

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/platforms/IPlatform.sol)

Platform is a contract that can mint and burn xusd (e.g. exchanger)

## Functions

### isTransferable

Check if a synth for a specific user is transferable

Synth can be transferable if all settlements is done

```solidity
function isTransferable(address token, address user) external view returns (bool);
```

**Parameters**

| Name    | Type      | Description              |
| ------- | --------- | ------------------------ |
| `token` | `address` | The address of the token |
| `user`  | `address` | The address of the user  |

**Returns**

| Name     | Type   | Description                                                       |
| -------- | ------ | ----------------------------------------------------------------- |
| `<none>` | `bool` | isTransferable True if the synth is transferable, false otherwise |

### totalFunds

Get the total market cap of the platform

```solidity
function totalFunds() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                                |
| -------- | --------- | ------------------------------------------ |
| `<none>` | `uint256` | totalFunds The total funds of the platform |
