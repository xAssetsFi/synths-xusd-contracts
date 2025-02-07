# IPool

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/IPool.sol)

Pool is a contract that manages the xusd mint and burn
This contract allows users to create a position that allow mint xusd by locking their collateral

## Functions

### supply

Supply collateral to the protocol

_Minimum health factor after supply should be greater than WAD_

```solidity
function supply(address token, uint256 amount) external;
```

**Parameters**

| Name     | Type      | Description                        |
| -------- | --------- | ---------------------------------- |
| `token`  | `address` | The address of the token to supply |
| `amount` | `uint256` | The amount of the token to supply  |

### withdraw

Withdraw collateral from the protocol

_Maximum health factor after withdraw should be greater than getMinHealthFactorForBorrow()_

```solidity
function withdraw(address token, uint256 amount, address to) external;
```

**Parameters**

| Name     | Type      | Description                                     |
| -------- | --------- | ----------------------------------------------- |
| `token`  | `address` | The address of the token to withdraw            |
| `amount` | `uint256` | The amount of the token to withdraw             |
| `to`     | `address` | The address to receive the withdrawn collateral |

### borrow

Borrow xusd from the protocol

_Minimum health factor after borrow should be greater than getMinHealthFactorForBorrow()_

```solidity
function borrow(uint256 amount, address to) external;
```

**Parameters**

| Name     | Type      | Description                              |
| -------- | --------- | ---------------------------------------- |
| `amount` | `uint256` | The amount of xusd to borrow             |
| `to`     | `address` | The address to receive the borrowed xusd |

### repay

Repay xusd to the protocol

_Maximum health factor after repay should be greater than WAD_

```solidity
function repay(uint256 amount) external;
```

**Parameters**

| Name     | Type      | Description                   |
| -------- | --------- | ----------------------------- |
| `amount` | `uint256` | The amount of shares to repay |

### liquidate

Liquidate a user's position

If position health factor < WAD, the position can be liquidated

Max amount of shares to liquidate is user's debt shares balance / 2

```solidity
function liquidate(address positionOwner, address token, uint256 shares, address to) external;
```

**Parameters**

| Name            | Type      | Description                                      |
| --------------- | --------- | ------------------------------------------------ |
| `positionOwner` | `address` | The address of the position owner to liquidate   |
| `token`         | `address` | The collateral token to liquidate                |
| `shares`        | `uint256` | The amount of shares to liquidate                |
| `to`            | `address` | The address to receive the liquidated collateral |

### supplyAndBorrow

Supply and borrow

_Minimum health factor after supplyAndBorrow should be greater than getMinHealthFactorForBorrow()_

```solidity
function supplyAndBorrow(address token, uint256 supplyAmount, uint256 borrowAmount, address borrowTo) external;
```

**Parameters**

| Name           | Type      | Description                              |
| -------------- | --------- | ---------------------------------------- |
| `token`        | `address` | The address of the token to supply       |
| `supplyAmount` | `uint256` | The amount of the token to supply        |
| `borrowAmount` | `uint256` | The amount of xusd to borrow             |
| `borrowTo`     | `address` | The address to receive the borrowed xusd |

### supplyETH

Supply ETH to the protocol

_The ETH will be converted to WETH and then supplied to the protocol_

```solidity
function supplyETH() external payable;
```

### withdrawETH

Withdraw ETH from the protocol

```solidity
function withdrawETH(uint256 amount, address to) external;
```

**Parameters**

| Name     | Type      | Description                              |
| -------- | --------- | ---------------------------------------- |
| `amount` | `uint256` | The amount of ETH to withdraw            |
| `to`     | `address` | The address to receive the withdrawn ETH |

### supplyETHAndBorrow

Supply ETH and borrow xusd

```solidity
function supplyETHAndBorrow(uint256 borrowAmount, address borrowTo) external payable;
```

**Parameters**

| Name           | Type      | Description                              |
| -------------- | --------- | ---------------------------------------- |
| `borrowAmount` | `uint256` | The amount of xusd to borrow             |
| `borrowTo`     | `address` | The address to receive the borrowed xusd |

### getHealthFactor

Get the health factor of a user

_The health factor is scaled by WAD_

```solidity
function getHealthFactor(address user) external view returns (uint256 healthFactor);
```

**Parameters**

| Name   | Type      | Description             |
| ------ | --------- | ----------------------- |
| `user` | `address` | The address of the user |

**Returns**

| Name           | Type      | Description                   |
| -------------- | --------- | ----------------------------- |
| `healthFactor` | `uint256` | The health factor of the user |

### calculateHealthFactor

Calculate the health factor of a position

```solidity
function calculateHealthFactor(CollateralData[] memory collateralData, uint256 shares)
    external
    view
    returns (uint256 healthFactor);
```

**Parameters**

| Name             | Type               | Description                                        |
| ---------------- | ------------------ | -------------------------------------------------- |
| `collateralData` | `CollateralData[]` | The collateral data to calculate the health factor |
| `shares`         | `uint256`          | The shares to calculate the health factor          |

**Returns**

| Name           | Type      | Description                       |
| -------------- | --------- | --------------------------------- |
| `healthFactor` | `uint256` | The health factor of the position |

### totalPositionCollateralValue

Calculate the total collateral value of a position

```solidity
function totalPositionCollateralValue(CollateralData[] memory collateralData)
    external
    view
    returns (uint256 collateralValue);
```

**Parameters**

| Name             | Type               | Description                                                    |
| ---------------- | ------------------ | -------------------------------------------------------------- |
| `collateralData` | `CollateralData[]` | The collateral data to calculate the total collateral value of |

**Returns**

| Name              | Type      | Description                                           |
| ----------------- | --------- | ----------------------------------------------------- |
| `collateralValue` | `uint256` | The total collateral value of the position in dollars |

### calculateCollateralValue

Dollars equivalent of a token amount

```solidity
function calculateCollateralValue(address token, uint256 amount) external view returns (uint256 collateralValue);
```

**Parameters**

| Name     | Type      | Description                                                   |
| -------- | --------- | ------------------------------------------------------------- |
| `token`  | `address` | The address of the token to calculate the collateral value of |
| `amount` | `uint256` | The amount of the token to calculate the collateral value of  |

**Returns**

| Name              | Type      | Description                                  |
| ----------------- | --------- | -------------------------------------------- |
| `collateralValue` | `uint256` | The collateral value of the token in dollars |

### getPosition

Get the position of a user

```solidity
function getPosition(address user) external view returns (Position memory position);
```

**Parameters**

| Name   | Type      | Description             |
| ------ | --------- | ----------------------- |
| `user` | `address` | The address of the user |

**Returns**

| Name       | Type       | Description              |
| ---------- | ---------- | ------------------------ |
| `position` | `Position` | The position of the user |

### isPositionExist

Check if a user's position exists

```solidity
function isPositionExist(address user) external view returns (bool isExists);
```

**Parameters**

| Name   | Type      | Description             |
| ------ | --------- | ----------------------- |
| `user` | `address` | The address of the user |

**Returns**

| Name       | Type   | Description                                         |
| ---------- | ------ | --------------------------------------------------- |
| `isExists` | `bool` | True if the user's position exists, false otherwise |

### totalFundsOnPlatforms

Get the price per share of the protocol

_totalFundsOnPlatforms = sum of all platforms' total funds_

```solidity
function totalFundsOnPlatforms() external view returns (uint256 totalFundsOnPlatforms);
```

**Returns**

| Name                    | Type      | Description                                             |
| ----------------------- | --------- | ------------------------------------------------------- |
| `totalFundsOnPlatforms` | `uint256` | The total funds on platforms of the protocol in dollars |

### pricePerShare

Calculate the price per debt share of the protocol

sum of total funds on platforms / debt shares totalSupply

_The price per debt share is scaled by WAD_

```solidity
function pricePerShare() external view returns (uint256 pps);
```

**Returns**

| Name  | Type      | Description                              |
| ----- | --------- | ---------------------------------------- |
| `pps` | `uint256` | The price per debt share of the protocol |

### convertToAssets

Convert shares to assets

```solidity
function convertToAssets(uint256 shares) external view returns (uint256 assets);
```

**Parameters**

| Name     | Type      | Description                               |
| -------- | --------- | ----------------------------------------- |
| `shares` | `uint256` | The amount of shares to convert to assets |

**Returns**

| Name     | Type      | Description                                |
| -------- | --------- | ------------------------------------------ |
| `assets` | `uint256` | The amount of assets converted from shares |

### convertToShares

Convert assets to shares

```solidity
function convertToShares(uint256 assets) external view returns (uint256 shares);
```

**Parameters**

| Name     | Type      | Description                               |
| -------- | --------- | ----------------------------------------- |
| `assets` | `uint256` | The amount of assets to convert to shares |

**Returns**

| Name     | Type      | Description                                |
| -------- | --------- | ------------------------------------------ |
| `shares` | `uint256` | The amount of shares converted from assets |

### calculateDeductionsWhileLiquidation

Calculate the deductions while liquidation

```solidity
function calculateDeductionsWhileLiquidation(address token, uint256 xusdAmount)
    external
    view
    returns (uint256 base, uint256 bonus, uint256 penalty);
```

**Parameters**

| Name         | Type      | Description                                             |
| ------------ | --------- | ------------------------------------------------------- |
| `token`      | `address` | The address of the token to calculate the deductions of |
| `xusdAmount` | `uint256` | The amount of xusd to calculate the deductions of       |

**Returns**

| Name      | Type      | Description                                                     |
| --------- | --------- | --------------------------------------------------------------- |
| `base`    | `uint256` | The base deduction equivalent to xusdAmount in collateral token |
| `bonus`   | `uint256` | The bonus deduction                                             |
| `penalty` | `uint256` | The penalty deduction                                           |

### getMinHealthFactorForBorrow

Get the minimum health factor to borrow

```solidity
function getMinHealthFactorForBorrow() external view returns (uint256 healthFactor);
```

**Returns**

| Name           | Type      | Description                                         |
| -------------- | --------- | --------------------------------------------------- |
| `healthFactor` | `uint256` | The minimum health factor for a user to borrow xusd |

### liquidationRatio

Get the liquidation ratio of the protocol

When the collateral value < total debt \* liquidation ratio, the position will be liquidated

```solidity
function liquidationRatio() external view returns (uint32 ratio);
```

**Returns**

| Name    | Type     | Description                           |
| ------- | -------- | ------------------------------------- |
| `ratio` | `uint32` | The liquidation ratio of the protocol |

### collateralRatio

Get the collateral ratio of the protocol

After a borrow, the collateral value should be greater than total debt \* collateral ratio

```solidity
function collateralRatio() external view returns (uint32 ratio);
```

**Returns**

| Name    | Type     | Description                          |
| ------- | -------- | ------------------------------------ |
| `ratio` | `uint32` | The collateral ratio of the protocol |

### liquidationBonusPercentagePoint

Get the liquidation bonus percentage point of the protocol

_ratio scaled by PRECISION_

```solidity
function liquidationBonusPercentagePoint() external view returns (uint32 ratio);
```

**Returns**

| Name    | Type     | Description                                            |
| ------- | -------- | ------------------------------------------------------ |
| `ratio` | `uint32` | The liquidation bonus percentage point of the protocol |

### liquidationPenaltyPercentagePoint

Get the liquidation penalty percentage point of the protocol

_ratio scaled by PRECISION_

```solidity
function liquidationPenaltyPercentagePoint() external view returns (uint32 ratio);
```

**Returns**

| Name    | Type     | Description                                              |
| ------- | -------- | -------------------------------------------------------- |
| `ratio` | `uint32` | The liquidation penalty percentage point of the protocol |

### loanFee

Get the loan fee of the protocol

```solidity
function loanFee() external view returns (uint32 fee);
```

**Returns**

| Name  | Type     | Description                  |
| ----- | -------- | ---------------------------- |
| `fee` | `uint32` | The loan fee of the protocol |

### debtShares

Get the debt shares contract

```solidity
function debtShares() external view returns (IDebtShares);
```

**Returns**

| Name     | Type          | Description                         |
| -------- | ------------- | ----------------------------------- |
| `<none>` | `IDebtShares` | debtShares The debt shares contract |

### collateralTokens

Get the collateral tokens of the protocol

```solidity
function collateralTokens() external view returns (address[] memory);
```

**Returns**

| Name     | Type        | Description                                            |
| -------- | ----------- | ------------------------------------------------------ |
| `<none>` | `address[]` | collateralTokens The collateral tokens of the protocol |

### isCollateralToken

Check if a token is a collateral token

```solidity
function isCollateralToken(address token) external view returns (bool);
```

**Parameters**

| Name    | Type      | Description                       |
| ------- | --------- | --------------------------------- |
| `token` | `address` | The address of the token to check |

**Returns**

| Name     | Type   | Description                                                           |
| -------- | ------ | --------------------------------------------------------------------- |
| `<none>` | `bool` | isCollateral True if the token is a collateral token, false otherwise |

### cooldownPeriod

Get the cooldown period of the protocol

```solidity
function cooldownPeriod() external view returns (uint32 period);
```

**Returns**

| Name     | Type     | Description                                |
| -------- | -------- | ------------------------------------------ |
| `period` | `uint32` | The cooldown period to execute next borrow |

### addCollateralToken

Allow a token as collateral

```solidity
function addCollateralToken(address token) external;
```

**Parameters**

| Name    | Type      | Description                                   |
| ------- | --------- | --------------------------------------------- |
| `token` | `address` | The address of the token to add as collateral |

### removeCollateralToken

Disallow a token as collateral

```solidity
function removeCollateralToken(address token) external;
```

**Parameters**

| Name    | Type      | Description                                      |
| ------- | --------- | ------------------------------------------------ |
| `token` | `address` | The address of the token to remove as collateral |

### setCooldownPeriod

Set the cooldown period

```solidity
function setCooldownPeriod(uint32 period) external;
```

**Parameters**

| Name     | Type     | Description                    |
| -------- | -------- | ------------------------------ |
| `period` | `uint32` | The cooldown period in seconds |

## Events

### Supply

```solidity
event Supply(address indexed positionOwner, address indexed token, uint256 amount);
```

### Withdraw

```solidity
event Withdraw(address indexed positionOwner, address indexed token, uint256 amount, address to, bool isPositionClosed);
```

### Borrow

```solidity
event Borrow(address indexed positionOwner, uint256 amount, address to);
```

### Repay

```solidity
event Repay(address indexed positionOwner, uint256 amount, uint256 remainingDebt);
```

### Liquidate

```solidity
event Liquidate(address indexed positionOwner, address indexed token, uint256 amount, address to);
```

### CollateralTokenAdded

```solidity
event CollateralTokenAdded(address token);
```

### CollateralTokenRemoved

```solidity
event CollateralTokenRemoved(address token);
```

### CollateralRatioSet

```solidity
event CollateralRatioSet(uint256 ratio);
```

### LiquidationRatioSet

```solidity
event LiquidationRatioSet(uint256 ratio);
```

### LiquidationPenaltyPercentagePointSet

```solidity
event LiquidationPenaltyPercentagePointSet(uint256 percentagePoint);
```

### LiquidationBonusPercentagePointSet

```solidity
event LiquidationBonusPercentagePointSet(uint256 percentagePoint);
```

### LoanFeeSet

```solidity
event LoanFeeSet(uint256 fee);
```

### CooldownPeriodSet

```solidity
event CooldownPeriodSet(uint256 period);
```

## Errors

### HealthFactorTooLow

```solidity
error HealthFactorTooLow(uint256 healthFactor, uint256 minHealthFactor);
```

### PositionNotInitialized

```solidity
error PositionNotInitialized();
```

### PositionHealthy

```solidity
error PositionHealthy();
```

### NotCollateralToken

```solidity
error NotCollateralToken();
```

### PositionNotExists

```solidity
error PositionNotExists();
```

### OnlyGatewayOrUser

```solidity
error OnlyGatewayOrUser();
```

### LiquidationAmountTooHigh

```solidity
error LiquidationAmountTooHigh(uint256 amount, uint256 maxAmount);
```

### NotEnoughCollateral

```solidity
error NotEnoughCollateral(uint256 required, uint256 available);
```

### Cooldown

```solidity
error Cooldown();
```

## Structs

### CollateralData

Collateral data of a position

```solidity
struct CollateralData {
    address token;
    uint256 amount;
}
```

**Properties**

| Name     | Type      | Description                                                         |
| -------- | --------- | ------------------------------------------------------------------- |
| `token`  | `address` | The address of the token that token should be allowed as collateral |
| `amount` | `uint256` | The amount of the token                                             |

### Position

Position data of a user

```solidity
struct Position {
    CollateralData[] collaterals;
    uint256 lastBorrowTimestamp;
}
```

**Properties**

| Name                  | Type               | Description                                                          |
| --------------------- | ------------------ | -------------------------------------------------------------------- |
| `collaterals`         | `CollateralData[]` | The list of collaterals that user locked in contract                 |
| `lastBorrowTimestamp` | `uint256`          | The timestamp of the last borrow see cooldownPeriod for more details |
