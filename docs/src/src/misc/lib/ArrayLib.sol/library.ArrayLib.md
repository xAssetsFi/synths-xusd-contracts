# ArrayLib

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/0d1cfa460704a82d2d714c759b70770bca8b942b/src/misc/lib/ArrayLib.sol)

## Functions

### remove

```solidity
function remove(address[] storage array, address target) internal;
```

### remove

```solidity
function remove(IPool.CollateralData[] storage array, address target) internal;
```

### getIndex

```solidity
function getIndex(IPool.CollateralData[] memory array, address token) internal pure returns (int8);
```

### getIndex

```solidity
function getIndex(address[] memory array, address token) internal pure returns (int8);
```
