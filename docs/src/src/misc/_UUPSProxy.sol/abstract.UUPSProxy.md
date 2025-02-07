# UUPSProxy

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/0d1cfa460704a82d2d714c759b70770bca8b942b/src/misc/_UUPSProxy.sol)

**Inherits:**
[ProviderKeeper](/src/misc/_ProviderKeeper.sol/abstract.ProviderKeeper.md), OwnableUpgradeable, UUPSUpgradeable

## Functions

### constructor

```solidity
constructor();
```

### \_\_UUPSProxy_init

```solidity
function __UUPSProxy_init(address _owner, address _provider) internal onlyInitializing;
```

### initialize

```solidity
function initialize(address _owner, address _provider) public virtual initializer;
```

### \_afterInitialize

```solidity
function _afterInitialize() internal virtual;
```

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal override onlyOwner;
```

### implementation

```solidity
function implementation() public view returns (address);
```
