# IPoolDataProvider

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/IPoolDataProvider.sol)

PoolDataProvider is a contract that provides data for the pool

## Functions

### getAggregatedPoolData

Get the aggregated data of the pool

```solidity
function getAggregatedPoolData(address user) external view returns (AggregatedPoolData memory);
```

**Parameters**

| Name   | Type      | Description                                |
| ------ | --------- | ------------------------------------------ |
| `user` | `address` | The address of the user to get the data of |

**Returns**

| Name     | Type                 | Description                     |
| -------- | -------------------- | ------------------------------- |
| `<none>` | `AggregatedPoolData` | The aggregated data of the pool |

### getPoolData

Get the data of the pool

```solidity
function getPoolData() external view returns (PoolData memory);
```

**Returns**

| Name     | Type       | Description          |
| -------- | ---------- | -------------------- |
| `<none>` | `PoolData` | The data of the pool |

### getUserPoolData

Get the data of the user's position

```solidity
function getUserPoolData(address user) external view returns (UserPoolData memory);
```

**Parameters**

| Name   | Type      | Description                                |
| ------ | --------- | ------------------------------------------ |
| `user` | `address` | The address of the user to get the data of |

**Returns**

| Name     | Type           | Description                     |
| -------- | -------------- | ------------------------------- |
| `<none>` | `UserPoolData` | The data of the user's position |

### reCalcHf

Re-calculate the health factor of the user's position

```solidity
function reCalcHf(address user, ReCalcHfParams memory params) external view returns (uint256);
```

**Parameters**

| Name     | Type             | Description                                                  |
| -------- | ---------------- | ------------------------------------------------------------ |
| `user`   | `address`        | The address of the user to re-calculate the health factor of |
| `params` | `ReCalcHfParams` | The parameters to re-calculate the health factor             |

**Returns**

| Name     | Type      | Description                              |
| -------- | --------- | ---------------------------------------- |
| `<none>` | `uint256` | The health factor of the user's position |

### getHealthFactor

Get the health factor of the user's position

Health factor it is a ratio between collateral value and debt value

If health factor < 1 (WAD), the position can be liquidated

If health factor > minHealthFactorForBorrow, the position can borrow XUSD

If position owner do not have any debt, health factor is type(uint256).max

_Health factor is scaled by WAD_

```solidity
function getHealthFactor(address user) external view returns (uint256);
```

**Parameters**

| Name   | Type      | Description                                         |
| ------ | --------- | --------------------------------------------------- |
| `user` | `address` | The address of the user to get the health factor of |

**Returns**

| Name     | Type      | Description                              |
| -------- | --------- | ---------------------------------------- |
| `<none>` | `uint256` | The health factor of the user's position |

### totalXUSDDebt

Get the total amount of XUSD debt

```solidity
function totalXUSDDebt(address user) external view returns (uint256);
```

**Parameters**

| Name   | Type      | Description                                                     |
| ------ | --------- | --------------------------------------------------------------- |
| `user` | `address` | The address of the user to get the total amount of XUSD debt of |

**Returns**

| Name     | Type      | Description                   |
| -------- | --------- | ----------------------------- |
| `<none>` | `uint256` | The total amount of XUSD debt |

### maxXUSDBorrow

Get the max amount of XUSD to borrow

_Max amount of xusd that can be borrowed and save collateral ratio_

```solidity
function maxXUSDBorrow(address user) external view returns (uint256);
```

**Parameters**

| Name   | Type      | Description                                                        |
| ------ | --------- | ------------------------------------------------------------------ |
| `user` | `address` | The address of the user to get the max amount of XUSD to borrow of |

**Returns**

| Name     | Type      | Description                      |
| -------- | --------- | -------------------------------- |
| `<none>` | `uint256` | The max amount of XUSD to borrow |

### maxWithdraw

Get the max amount of shares to withdraw

_Max amount of collateral that can be withdrawn and save collateral ratio_

```solidity
function maxWithdraw(address user, address token)
    external
    view
    returns (uint256 tokenAmount, uint256 dollarAmountInTokenDecimals);
```

**Parameters**

| Name    | Type      | Description                                                             |
| ------- | --------- | ----------------------------------------------------------------------- |
| `user`  | `address` | The address of the user to get the max amount of shares to withdraw of  |
| `token` | `address` | The address of the token to get the max amount of shares to withdraw of |

### findLiquidationOpportunity

Find the liquidation opportunity of the user's position

```solidity
function findLiquidationOpportunity(address[] calldata users)
    external
    view
    returns (address[] memory tokens, uint256[] memory shares);
```

**Parameters**

| Name    | Type        | Description                                                       |
| ------- | ----------- | ----------------------------------------------------------------- |
| `users` | `address[]` | The addresses of the users to find the liquidation opportunity of |

## Structs

### AggregatedPoolData

Aggregated data of the pool

```solidity
struct AggregatedPoolData {
    PoolData poolData;
    UserPoolData userPoolData;
    bool paused;
    uint256 oraclePrecision;
}
```

**Properties**

| Name              | Type           | Description                     |
| ----------------- | -------------- | ------------------------------- |
| `poolData`        | `PoolData`     | The data of the pool            |
| `userPoolData`    | `UserPoolData` | The data of the user's position |
| `paused`          | `bool`         | Whether the pool is paused      |
| `oraclePrecision` | `uint256`      | The precision of the oracle     |

### PoolData

Data of the pool

```solidity
struct PoolData {
    uint256 pps;
    uint256 debtSharesBalance;
    uint256 minHealthFactorForBorrow;
    uint32 liquidationRatio;
    uint32 collateralRatio;
    uint32 cooldownPeriod;
    uint32 loanFee;
    uint256 healthFactorPrecision;
    uint256 ratioPrecision;
}
```

**Properties**

| Name                       | Type      | Description            |
| -------------------------- | --------- | ---------------------- |
| `pps`                      | `uint256` |                        |
| `debtSharesBalance`        | `uint256` |                        |
| `minHealthFactorForBorrow` | `uint256` |                        |
| `liquidationRatio`         | `uint32`  |                        |
| `collateralRatio`          | `uint32`  |                        |
| `cooldownPeriod`           | `uint32`  |                        |
| `loanFee`                  | `uint32`  |                        |
| `healthFactorPrecision`    | `uint256` | is scaled by WAD       |
| `ratioPrecision`           | `uint256` | is scaled by PRECISION |

### Token

```solidity
struct Token {
    address token;
    string name;
    string symbol;
    uint8 decimals;
    uint256 price;
    uint256 balance;
}
```

### UserPoolData

```solidity
struct UserPoolData {
    IPool.Position position;
    Token[] tokensOnWallet;
    uint256 healthFactor;
    uint256 totalXUSDDebt;
    uint256 debtSharesBalance;
    uint256 collateralValue;
    uint256 maxXUSDBorrow;
}
```

### ReCalcHfParams

Params for re-calculating the health factor

```solidity
struct ReCalcHfParams {
    address collateralToken;
    int256 collateralAmount;
    int256 debtAmount;
}
```

**Properties**

| Name               | Type      | Description                                                                                      |
| ------------------ | --------- | ------------------------------------------------------------------------------------------------ |
| `collateralToken`  | `address` | The token to be supplied or withdrawn                                                            |
| `collateralAmount` | `int256`  | The amount of collateral to be supplied or withdrawn, positive for supply, negative for withdraw |
| `debtAmount`       | `int256`  | The amount of debt to be borrowed or repaid, positive for borrow, negative for repay             |
