# OracleAdapter

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/6d08ef5181d5c362f591b78a92f5298841e52c1d/src/periphery/OracleAdapter.sol)

**Inherits:**
[IOracleAdapter](/src/interface/IOracleAdapter.sol/interface.IOracleAdapter.md), [UUPSProxy](/src/common/_UUPSProxy.sol/abstract.UUPSProxy.md)

## State Variables

### diaOracle

```solidity
IDIAOracleV2 public diaOracle;
```

### fallbackOracle

```solidity
IOracleAdapter public fallbackOracle;
```

### keys

```solidity
mapping(address token => string key) public keys;
```

## Functions

### initialize

```solidity
function initialize(address _owner, address _provider, address _diaOracle) public initializer;
```

### getPrice

```solidity
function getPrice(address token) external view returns (uint256);
```

### precision

```solidity
function precision() public pure returns (uint256);
```

### \_validatePrice

```solidity
function _validatePrice(uint256 price, address token) internal view returns (uint256);
```

### setKey

```solidity
function setKey(address token, string memory key) external onlyOwner;
```

### setDiaOracle

```solidity
function setDiaOracle(address diaOracle_)
    external
    onlyOwner
    validInterface(diaOracle_, type(IDIAOracleV2).interfaceId);
```

### setFallbackOracle

```solidity
function setFallbackOracle(address fallbackOracle_)
    external
    onlyOwner
    validInterface(fallbackOracle_, type(IOracleAdapter).interfaceId);
```

### \_afterInitialize

```solidity
function _afterInitialize() internal override;
```
