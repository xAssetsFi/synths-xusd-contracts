# Base

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/0d1cfa460704a82d2d714c759b70770bca8b942b/src/misc/_Base.sol)

**Inherits:**
[Errors](/src/misc/_Errors.sol/contract.Errors.md), Initializable, [ERC165Registry](/src/misc/_ERC165Registry.sol/abstract.ERC165Registry.md)

## State Variables

### WAD

```solidity
uint256 constant WAD = 1e18;
```

### PRECISION

```solidity
uint256 constant PRECISION = 10000;
```

## Functions

### validInterface

```solidity
modifier validInterface(address addr, bytes4 interfaceId);
```

### noZeroAddress

```solidity
modifier noZeroAddress(address addr);
```

### noZeroUint

```solidity
modifier noZeroUint(uint256 amount);
```
