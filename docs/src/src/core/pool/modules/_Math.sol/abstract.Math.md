# Math

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/core/pool/modules/_Math.sol)

**Inherits:**
[UUPSProxy](/src/common/_UUPSProxy.sol/abstract.UUPSProxy.md), [IPool](/src/interface/IPool.sol/interface.IPool.md)

## State Variables

### debtShares

```solidity
IDebtShares public debtShares;
```

### feeReceiver

```solidity
address public feeReceiver;
```

### collateralRatio

```solidity
uint32 public collateralRatio;
```

### liquidationRatio

```solidity
uint32 public liquidationRatio;
```

### liquidationPenaltyPercentagePoint

```solidity
uint32 public liquidationPenaltyPercentagePoint;
```

### liquidationBonusPercentagePoint

```solidity
uint32 public liquidationBonusPercentagePoint;
```

### loanFee

```solidity
uint32 public loanFee;
```

### cooldownPeriod

Cooldown period to execute repay after borrow

```solidity
uint32 public cooldownPeriod;
```

### \_positions

```solidity
mapping(address user => Position) internal _positions;
```

### isCollateralToken

```solidity
mapping(address token => bool isCollateral) public isCollateralToken;
```

### \_collateralTokens

```solidity
address[] internal _collateralTokens;
```

## Functions

### \_\_Math_init

```solidity
function __Math_init(
    address _feeReceiver,
    address _debtShares,
    uint32 _collateralRatio,
    uint32 _liquidationRatio,
    uint32 _liquidationPenaltyPercentagePoint,
    uint32 _liquidationBonusPercentagePoint,
    uint32 _loanFee,
    uint32 _cooldownPeriod
)
    internal
    onlyInitializing
    noZeroAddress(_feeReceiver)
    noZeroAddress(_debtShares)
    validInterface(_debtShares, type(IDebtShares).interfaceId);
```

### calculateHealthFactor

```solidity
function calculateHealthFactor(CollateralData[] memory collateralData, uint256 shares)
    public
    view
    returns (uint256 hf);
```

### totalPositionCollateralValue

```solidity
function totalPositionCollateralValue(CollateralData[] memory collaterals)
    public
    view
    returns (uint256 collateralValue);
```

### calculateCollateralValue

```solidity
function calculateCollateralValue(address token, uint256 amount) public view returns (uint256 collateralValue);
```

### totalFundsOnPlatforms

```solidity
function totalFundsOnPlatforms() public view returns (uint256 tf);
```

### pricePerShare

```solidity
function pricePerShare() public view returns (uint256 pps);
```

### getMinHealthFactorForBorrow

```solidity
function getMinHealthFactorForBorrow() public view returns (uint256 hf);
```

### convertToAssets

```solidity
function convertToAssets(uint256 shares) public view returns (uint256 assets);
```

### convertToShares

```solidity
function convertToShares(uint256 assets) public view returns (uint256 shares);
```

### calculateDeductionsWhileLiquidation

```solidity
function calculateDeductionsWhileLiquidation(address token, uint256 xusdAmount)
    public
    view
    returns (uint256 base, uint256 bonus, uint256 penalty);
```
