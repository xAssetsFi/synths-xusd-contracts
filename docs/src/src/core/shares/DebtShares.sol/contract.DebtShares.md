# DebtShares

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/core/shares/DebtShares.sol)

**Inherits:**
[Rewarder](/src/core/shares/modules/_Rewarder.sol/abstract.Rewarder.md)

DebtShares is a contract that manages the debt shares
Debt shares are minted when a user mint xusd and burned when a user burn xusd
Only pool contract can transfer debt shares

## Functions

### mint

```solidity
function mint(address to, uint256 amount) external onlyPool updateRewards(to);
```

### burn

```solidity
function burn(address from, uint256 amount) external onlyPool updateRewards(from);
```

### \_update

```solidity
function _update(address from, address to, uint256 amount) internal override onlyPool;
```

### onlyPool

```solidity
modifier onlyPool();
```

### initialize

```solidity
function initialize(address _owner, address _provider, string memory _name, string memory _symbol) public initializer;
```

### \_afterInitialize

```solidity
function _afterInitialize() internal override;
```

### initialize

```solidity
function initialize(address, address) public override initializer;
```
