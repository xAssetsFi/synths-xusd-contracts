# ISynth

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/platforms/synths/ISynth.sol)

**Inherits:**
IERC20, IERC20Metadata

## Functions

### initialize

```solidity
function initialize(address _owner, address _provider, string memory _name, string memory _symbol) external;
```

### mint

```solidity
function mint(address to, uint256 amount) external;
```

### burn

```solidity
function burn(address from, uint256 amount) external;
```

## Errors

### NotTransferable

```solidity
error NotTransferable();
```
