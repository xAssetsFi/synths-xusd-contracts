// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IDebtShares} from "./IDebtShares.sol";

/// @notice Pool is a contract that manages the xusd mint and burn
/// This contract allows users to create a position that allow mint xusd by locking their collateral
interface IPool {
    /// @notice Collateral data of a position
    /// @param token The address of the token that token should be allowed as collateral
    /// @param amount The amount of the token
    struct CollateralData {
        address token;
        uint256 amount;
    }

    /// @notice Position data of a user
    /// @param collaterals The list of collaterals that user locked in contract
    /// @param lastBorrowTimestamp The timestamp of the last borrow see cooldownPeriod for more details
    /// @param lastChargedFeeTimestamp The timestamp of the last charged stability fee
    struct Position {
        CollateralData[] collaterals;
        uint256 lastBorrowTimestamp;
        uint256 lastChargedFeeTimestamp;
    }

    /* ======== User Functions ======== */

    /// @notice Supply collateral to the protocol
    /// @param token The address of the token to supply
    /// @param amount The amount of the token to supply
    /// @dev Minimum health factor after supply should be greater than WAD
    function supply(address token, uint256 amount) external;

    /// @notice Withdraw collateral from the protocol
    /// @param token The address of the token to withdraw
    /// @param amount The amount of the token to withdraw
    /// @param to The address to receive the withdrawn collateral
    /// @dev Maximum health factor after withdraw should be greater than getMinHealthFactorForBorrow()
    function withdraw(address token, uint256 amount, address to) external;

    /// @notice Borrow xusd from the protocol
    /// @param amount The amount of xusd to borrow
    /// @param to The address to receive the borrowed xusd
    /// @dev Minimum health factor after borrow should be greater than getMinHealthFactorForBorrow()
    function borrow(uint256 amount, address to) external;

    /// @notice Repay xusd to the protocol
    /// @param amount The amount of shares to repay
    /// @dev Maximum health factor after repay should be greater than WAD
    function repay(uint256 amount) external;

    /// @notice Liquidate a user's position
    /// @param positionOwner    The address of the position owner to liquidate
    /// @param token The collateral token to liquidate
    /// @param shares The amount of shares to liquidate
    /// @param to The address to receive the liquidated collateral
    /// @notice If position health factor < WAD, the position can be liquidated
    /// @notice Max amount of shares to liquidate is user's debt shares balance / 2
    function liquidate(address positionOwner, address token, uint256 shares, address to) external;

    /// @notice Supply and borrow
    /// @param token The address of the token to supply
    /// @param supplyAmount The amount of the token to supply
    /// @param borrowAmount The amount of xusd to borrow
    /// @param borrowTo The address to receive the borrowed xusd
    /// @dev Minimum health factor after supplyAndBorrow should be greater than getMinHealthFactorForBorrow()
    function supplyAndBorrow(
        address token,
        uint256 supplyAmount,
        uint256 borrowAmount,
        address borrowTo
    ) external;

    /// @notice Supply ETH to the protocol
    /// @dev The ETH will be converted to WETH and then supplied to the protocol
    function supplyETH() external payable;

    /// @notice Withdraw ETH from the protocol
    /// @param amount The amount of ETH to withdraw
    /// @param to The address to receive the withdrawn ETH
    function withdrawETH(uint256 amount, address to) external;

    /// @notice Supply ETH and borrow xusd
    /// @param borrowAmount The amount of xusd to borrow
    /// @param borrowTo The address to receive the borrowed xusd
    function supplyETHAndBorrow(uint256 borrowAmount, address borrowTo) external payable;

    /* ======== View Functions ======== */

    /// @notice Get the health factor of a user
    /// @param user The address of the user
    /// @return healthFactor The health factor of the user
    /// @dev The health factor is scaled by WAD
    function getHealthFactor(address user) external view returns (uint256 healthFactor);

    /// @notice Calculate the health factor of a position
    /// @param collateralData The collateral data to calculate the health factor
    /// @param shares The shares to calculate the health factor
    /// @return healthFactor The health factor of the position
    function calculateHealthFactor(CollateralData[] memory collateralData, uint256 shares)
        external
        view
        returns (uint256 healthFactor);

    /// @notice Calculate the total collateral value of a position
    /// @param collateralData The collateral data to calculate the total collateral value of
    /// @return collateralValue The total collateral value of the position in dollars
    function totalPositionCollateralValue(CollateralData[] memory collateralData)
        external
        view
        returns (uint256 collateralValue);

    /// @notice Dollars equivalent of a token amount
    /// @param token The address of the token to calculate the collateral value of
    /// @param amount The amount of the token to calculate the collateral value of
    /// @return collateralValue The collateral value of the token in dollars
    function calculateCollateralValue(address token, uint256 amount)
        external
        view
        returns (uint256 collateralValue);

    /// @notice Calculate the stability fee of a user
    /// @param user The address of the user
    /// @return stabilityFee The stability fee of the user
    function calculateStabilityFee(address user) external view returns (uint256 stabilityFee);

    /// @notice Get the position of a user
    /// @param user The address of the user
    /// @return position The position of the user
    function getPosition(address user) external view returns (Position memory position);

    /// @notice Check if a user's position exists
    /// @param user The address of the user
    /// @return isExists True if the user's position exists, false otherwise
    function isPositionExist(address user) external view returns (bool isExists);

    /// @notice Get the price per share of the protocol
    /// @return totalFundsOnPlatforms The total funds on platforms of the protocol in dollars
    /// @dev totalFundsOnPlatforms = sum of all platforms' total funds
    function totalFundsOnPlatforms() external view returns (uint256 totalFundsOnPlatforms);

    /// @notice Calculate the price per debt share of the protocol
    /// @notice sum of total funds on platforms / debt shares totalSupply
    /// @return pps The price per debt share of the protocol
    /// @dev The price per debt share is scaled by WAD
    function pricePerShare() external view returns (uint256 pps);

    /// @notice Convert shares to assets
    /// @param shares The amount of shares to convert to assets
    /// @return assets The amount of assets converted from shares
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice Convert assets to shares
    /// @param assets The amount of assets to convert to shares
    /// @return shares The amount of shares converted from assets
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice Calculate the deductions while liquidation
    /// @param token The address of the token to calculate the deductions of
    /// @param xusdAmount The amount of xusd to calculate the deductions of
    /// @return base The base deduction equivalent to xusdAmount in collateral token
    /// @return bonus The bonus deduction
    /// @return penalty The penalty deduction
    function calculateDeductionsWhileLiquidation(address token, uint256 xusdAmount)
        external
        view
        returns (uint256 base, uint256 bonus, uint256 penalty);

    /// @notice Get the minimum health factor to borrow
    /// @return healthFactor The minimum health factor for a user to borrow xusd
    function getMinHealthFactorForBorrow() external view returns (uint256 healthFactor);

    /// @notice Get the liquidation ratio of the protocol
    /// @return ratio The liquidation ratio of the protocol
    /// @notice When the collateral value < total debt * liquidation ratio, the position will be liquidated
    function liquidationRatio() external view returns (uint32 ratio);

    /// @notice Get the collateral ratio of the protocol
    /// @return ratio The collateral ratio of the protocol
    /// @notice After a borrow, the collateral value should be greater than total debt * collateral ratio
    function collateralRatio() external view returns (uint32 ratio);

    /// @notice Get the liquidation bonus percentage point of the protocol
    /// @return ratio The liquidation bonus percentage point of the protocol
    /// @dev ratio scaled by PRECISION
    function liquidationBonusPercentagePoint() external view returns (uint32 ratio);

    /// @notice Get the liquidation penalty percentage point of the protocol
    /// @return ratio The liquidation penalty percentage point of the protocol
    /// @dev ratio scaled by PRECISION
    function liquidationPenaltyPercentagePoint() external view returns (uint32 ratio);

    /// @notice Get the loan fee of the protocol
    /// @return fee The loan fee of the protocol
    function loanFee() external view returns (uint32 fee);

    /// @notice Get the stability fee of the protocol
    /// @return fee The stability fee that user pay for holding debt shares of the protocol
    function stabilityFee() external view returns (uint32 fee);

    /// @notice Get the debt shares contract
    /// @return debtShares The debt shares contract
    function debtShares() external view returns (IDebtShares);

    /// @notice Get the collateral tokens of the protocol
    /// @return collateralTokens The collateral tokens of the protocol
    function collateralTokens() external view returns (address[] memory);

    /// @notice Check if a token is a collateral token
    /// @param token The address of the token to check
    /// @return isCollateral True if the token is a collateral token, false otherwise
    function isCollateralToken(address token) external view returns (bool);

    /// @notice Get the cooldown period of the protocol
    /// @return period The cooldown period to execute next borrow
    function cooldownPeriod() external view returns (uint32 period);

    /* ======== Admin Functions ======== */

    /// @notice Allow a token as collateral
    /// @param token The address of the token to add as collateral
    function addCollateralToken(address token) external;

    /// @notice Disallow a token as collateral
    /// @param token The address of the token to remove as collateral
    function removeCollateralToken(address token) external;

    /// @notice Set the cooldown period
    /// @param period The cooldown period in seconds
    function setCooldownPeriod(uint32 period) external;

    /* ======== Events ======== */

    event Supply(address indexed positionOwner, address indexed token, uint256 amount);
    event Withdraw(
        address indexed positionOwner,
        address indexed token,
        uint256 amount,
        address to,
        bool isPositionClosed
    );
    event Borrow(address indexed positionOwner, uint256 amount, address to);
    event Repay(address indexed positionOwner, uint256 amount, uint256 remainingDebt);
    event Liquidate(
        address indexed positionOwner, address indexed token, uint256 amount, address to
    );

    event CollateralTokenAdded(address token);
    event CollateralTokenRemoved(address token);
    event CollateralRatioSet(uint256 ratio);
    event LiquidationRatioSet(uint256 ratio);
    event LiquidationPenaltyPercentagePointSet(uint256 percentagePoint);
    event LiquidationBonusPercentagePointSet(uint256 percentagePoint);
    event LoanFeeSet(uint256 fee);
    event StabilityFeeSet(uint256 fee);
    event CooldownPeriodSet(uint256 period);

    /* ======== Errors ======== */

    error HealthFactorTooLow(uint256 healthFactor, uint256 minHealthFactor);
    error PositionNotInitialized();
    error PositionHealthy();
    error NotCollateralToken();
    error PositionNotExists();
    error OnlyGatewayOrUser();
    error LiquidationAmountTooHigh(uint256 amount, uint256 maxAmount);
    error NotEnoughCollateral(uint256 required, uint256 available);
    error Cooldown();
    error LiquidationDeductionsTooHigh();
    error LiquidationRatioTooLow();
}
