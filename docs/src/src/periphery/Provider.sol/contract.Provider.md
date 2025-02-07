# Provider

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/periphery/Provider.sol)

**Inherits:**
[IProvider](/src/interface/IProvider.sol/interface.IProvider.md), [Base](/src/common/_Base.sol/abstract.Base.md), PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable

## State Variables

### \_xusd

```solidity
address private _xusd;
```

### \_pool

```solidity
address private _pool;
```

### \_oracle

```solidity
address private _oracle;
```

### \_exchanger

```solidity
address private _exchanger;
```

### isPlatform

```solidity
mapping(address => bool) public isPlatform;
```

### \_platforms

```solidity
IPlatform[] private _platforms;
```

## Functions

### constructor

```solidity
constructor();
```

### initialize

```solidity
function initialize(address _owner) public initializer;
```

### setXUSD

```solidity
function setXUSD(address newXUSD)
    external
    onlyOwner
    noZeroAddress(newXUSD)
    validInterface(newXUSD, type(ISynth).interfaceId);
```

### setExchanger

```solidity
function setExchanger(address newExchanger)
    external
    onlyOwner
    noZeroAddress(newExchanger)
    validInterface(newExchanger, type(IExchanger).interfaceId);
```

### setPool

```solidity
function setPool(address newPool)
    external
    onlyOwner
    noZeroAddress(newPool)
    validInterface(newPool, type(IPool).interfaceId);
```

### setOracle

```solidity
function setOracle(address newOracle)
    external
    onlyOwner
    noZeroAddress(newOracle)
    validInterface(newOracle, type(IOracleAdapter).interfaceId);
```

### xusd

```solidity
function xusd() external view noZeroAddress(_xusd) returns (ISynth);
```

### exchanger

```solidity
function exchanger() external view noZeroAddress(_exchanger) returns (IExchanger);
```

### pool

```solidity
function pool() external view noZeroAddress(_pool) returns (IPool);
```

### oracle

```solidity
function oracle() external view noZeroAddress(_oracle) returns (IOracleAdapter);
```

### platforms

```solidity
function platforms() external view returns (IPlatform[] memory);
```

### isPaused

```solidity
function isPaused() public view returns (bool);
```

### implementation

```solidity
function implementation() external view returns (address);
```

### pause

```solidity
function pause() external onlyOwner;
```

### unpause

```solidity
function unpause() external onlyOwner;
```

### \_addPlatform

```solidity
function _addPlatform(address platform) internal validInterface(platform, type(IPlatform).interfaceId);
```

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal override onlyOwner;
```
