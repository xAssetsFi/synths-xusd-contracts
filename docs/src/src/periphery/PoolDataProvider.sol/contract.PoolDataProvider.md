# PoolDataProvider

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/periphery/PoolDataProvider.sol)

**Inherits:**
[IPoolDataProvider](/src/interface/IPoolDataProvider.sol/interface.IPoolDataProvider.md), [UUPSProxy](/src/common/_UUPSProxy.sol/abstract.UUPSProxy.md)

## Functions

### getAggregatedPoolData

```solidity
function getAggregatedPoolData(address user) external view returns (AggregatedPoolData memory data);
```

### getPoolData

```solidity
function getPoolData() public view returns (PoolData memory data);
```

### getUserPoolData

```solidity
function getUserPoolData(address user) public view returns (UserPoolData memory data);
```

### getHealthFactor

```solidity
function getHealthFactor(address user) public view returns (uint256);
```

### reCalcHf

```solidity
function reCalcHf(address user, ReCalcHfParams memory params) public view returns (uint256);
```

### totalXUSDDebt

```solidity
function totalXUSDDebt(address user) public view returns (uint256);
```

### maxXUSDBorrow

```solidity
function maxXUSDBorrow(address user) public view returns (uint256 maxBorrow);
```

### maxWithdraw

```solidity
function maxWithdraw(address user, address token)
    public
    view
    returns (uint256 tokenAmount, uint256 dollarAmountInTokenDecimals);
```

### findLiquidationOpportunity

Find the liquidation opportunity for the users

This is gas efficient way to find the liquidation opportunity for the users

```solidity
function findLiquidationOpportunity(address[] calldata users)
    external
    view
    returns (address[] memory token, uint256[] memory shares);
```

**Parameters**

| Name    | Type        | Description                                       |
| ------- | ----------- | ------------------------------------------------- |
| `users` | `address[]` | The users to find the liquidation opportunity for |

**Returns**

| Name     | Type        | Description             |
| -------- | ----------- | ----------------------- |
| `token`  | `address[]` | The tokens to liquidate |
| `shares` | `uint256[]` | The shares to liquidate |

### \_convertToAssets

```solidity
function _convertToAssets(uint256 shares, uint256 pricePerShare, uint256 xusdPrecision)
    internal
    pure
    returns (uint256 assets);
```

### \_convertToShares

```solidity
function _convertToShares(uint256 assets, uint256 pricePerShare, uint256 xusdPrecision)
    internal
    pure
    returns (uint256 shares);
```

### \_getMaxSharesToLiquidate

```solidity
function _getMaxSharesToLiquidate(
    IPool.CollateralData memory collateral,
    uint256 collateralPrice,
    uint256 positionShares,
    uint256 pricePerShare,
    uint256 xusdPrecision,
    uint256 oraclePrecision
) internal view returns (uint256 shares);
```

### \_calculateHealthFactor

```solidity
function _calculateHealthFactor(
    IPool.CollateralData[] memory collateralData,
    uint256 totalDebt,
    uint256 liquidationRatio,
    IOracleAdapter oracle,
    uint256 oraclePrecision
) internal view returns (uint256 hf);
```

### \_totalPositionCollateralValue

```solidity
function _totalPositionCollateralValue(
    IPool.CollateralData[] memory collaterals,
    IOracleAdapter oracle,
    uint256 oraclePrecision
) internal view returns (uint256 collateralValue);
```

### getTokensBalances

```solidity
function getTokensBalances(address user, address[] memory tokens) public view returns (Token[] memory data);
```

### \_copyPositionAndPushCollateral

```solidity
function _copyPositionAndPushCollateral(IPool.Position memory position, ReCalcHfParams memory params)
    internal
    pure
    returns (IPool.Position memory);
```

### \_afterInitialize

```solidity
function _afterInitialize() internal override;
```
