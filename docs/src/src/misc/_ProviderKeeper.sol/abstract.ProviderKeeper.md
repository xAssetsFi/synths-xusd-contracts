# ProviderKeeper

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/0d1cfa460704a82d2d714c759b70770bca8b942b/src/misc/_ProviderKeeper.sol)

**Inherits:**
[Base](/src/misc/_Base.sol/abstract.Base.md)

## State Variables

### \_provider

```solidity
IProvider private _provider;
```

## Functions

### \_\_ProviderKeeper_init

```solidity
function __ProviderKeeper_init(address newProvider)
    internal
    noZeroAddress(newProvider)
    onlyInitializing
    validInterface(newProvider, type(IProvider).interfaceId);
```

### provider

```solidity
function provider() internal view noZeroAddress(address(_provider)) returns (IProvider);
```

### noPaused

```solidity
modifier noPaused();
```
