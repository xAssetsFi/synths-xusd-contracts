// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IPool} from "./IPool.sol";

/// @notice PoolDataProvider is a contract that provides data for the pool
interface IPoolDataProvider {
    /// @notice Aggregated data of the pool
    /// @param poolData The data of the pool
    /// @param userPoolData The data of the user's position
    /// @param paused Whether the pool is paused
    /// @param oraclePrecision The precision of the oracle
    struct AggregatedPoolData {
        PoolData poolData;
        UserPoolData userPoolData;
        bool paused;
        uint256 oraclePrecision;
    }

    /// @notice Data of the pool
    /// @param ratioPrecision is scaled by PRECISION
    /// @param healthFactorPrecision is scaled by WAD
    struct PoolData {
        uint256 pps;
        uint256 debtSharesBalance;
        uint256 minHealthFactorForBorrow;
        uint32 liquidationRatio;
        uint32 collateralRatio;
        uint32 cooldownPeriod;
        uint32 loanFee;
        uint32 stabilityFee;
        uint256 healthFactorPrecision;
        uint256 ratioPrecision;
    }

    struct Token {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint256 price;
        uint256 balance;
    }

    struct UserPoolData {
        IPool.Position position;
        Token[] tokensOnWallet;
        uint256 healthFactor;
        uint256 totalXUSDDebt;
        uint256 debtSharesBalance;
        uint256 collateralValue;
        uint256 maxXUSDBorrow;
    }

    /// @notice Params for re-calculating the health factor
    /// @param collateralToken The token to be supplied or withdrawn
    /// @param collateralAmount The amount of collateral to be supplied or withdrawn, positive for supply, negative for withdraw
    /// @param debtAmount The amount of debt to be borrowed or repaid, positive for borrow, negative for repay
    struct ReCalcHfParams {
        address collateralToken;
        int256 collateralAmount;
        int256 debtAmount;
    }

    /* ======== POOL ======== */

    /// @notice Get the aggregated data of the pool
    /// @param user The address of the user to get the data of
    /// @return The aggregated data of the pool
    function getAggregatedPoolData(address user)
        external
        view
        returns (AggregatedPoolData memory);

    /// @notice Get the data of the pool
    /// @return The data of the pool
    function getPoolData() external view returns (PoolData memory);

    /// @notice Get the data of the user's position
    /// @param user The address of the user to get the data of
    /// @return The data of the user's position
    function getUserPoolData(address user) external view returns (UserPoolData memory);

    /// @notice Re-calculate the health factor of the user's position
    /// @param user The address of the user to re-calculate the health factor of
    /// @param params The parameters to re-calculate the health factor
    /// @return The health factor of the user's position
    function reCalcHf(address user, ReCalcHfParams memory params) external view returns (uint256);

    /// @notice Get the health factor of the user's position
    /// @param user The address of the user to get the health factor of
    /// @return The health factor of the user's position
    /// @dev Health factor is scaled by WAD
    /// @notice Health factor it is a ratio between collateral value and debt value
    /// @notice If health factor < 1 (WAD), the position can be liquidated
    /// @notice If health factor > minHealthFactorForBorrow, the position can borrow XUSD
    /// @notice If position owner do not have any debt, health factor is type(uint256).max
    function getHealthFactor(address user) external view returns (uint256);

    /// @notice Get the total amount of XUSD debt
    /// @param user The address of the user to get the total amount of XUSD debt of
    /// @return The total amount of XUSD debt
    function totalXUSDDebt(address user) external view returns (uint256);

    /// @notice Get the max amount of XUSD to borrow
    /// @param user The address of the user to get the max amount of XUSD to borrow of
    /// @return The max amount of XUSD to borrow
    /// @dev Max amount of xusd that can be borrowed and save collateral ratio
    function maxXUSDBorrow(address user) external view returns (uint256);

    /// @notice Get the max amount of shares to withdraw
    /// @param user The address of the user to get the max amount of shares to withdraw of
    /// @param token The address of the token to get the max amount of shares to withdraw of
    /// @dev Max amount of collateral that can be withdrawn and save collateral ratio
    function maxWithdraw(address user, address token)
        external
        view
        returns (uint256 tokenAmount, uint256 dollarAmountInTokenDecimals);

    /// @notice Find the liquidation opportunity of the user's position
    /// @param users The addresses of the users to find the liquidation opportunity of
    function findLiquidationOpportunity(address[] calldata users)
        external
        view
        returns (address[] memory tokens, uint256[] memory shares);
}
