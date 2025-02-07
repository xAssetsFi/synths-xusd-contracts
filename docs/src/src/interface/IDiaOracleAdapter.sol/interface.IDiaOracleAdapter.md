# IDiaOracleAdapter

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/IDiaOracleAdapter.sol)

Oracle adapter interface for dai oracle

## Functions

### setKey

```solidity
function setKey(address token, string memory key) external;
```

### setDiaOracle

```solidity
function setDiaOracle(address diaOracle_) external;
```

## Events

### NewKey

```solidity
event NewKey(address token, string key);
```

### DiaOracleChanged

```solidity
event DiaOracleChanged(address oldDiaOracle, address newDiaOracle);
```
