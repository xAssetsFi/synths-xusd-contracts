// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {UUPSImplementation} from "src/common/_UUPSImplementation.sol";

import {IPoolDataProvider} from "src/interface/IPoolDataProvider.sol";
import {IPool} from "src/interface/IPool.sol";
import {IOracleAdapter} from "src/interface/IOracleAdapter.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {PoolArrayLib, INDEX_NOT_FOUND} from "src/lib/PoolArrayLib.sol";

contract PoolDataProvider is IPoolDataProvider, UUPSImplementation {
    using PoolArrayLib for IPool.CollateralData[];

    function getAggregatedPoolData(address user)
        external
        view
        returns (AggregatedPoolData memory data)
    {
        data = AggregatedPoolData(
            getPoolData(),
            getUserPoolData(user),
            provider().isPaused(),
            provider().oracle().precision()
        );
    }

    function getPoolData() public view returns (PoolData memory data) {
        IPool pool = provider().pool();

        data = PoolData(
            pool.pricePerShare(),
            pool.debtShares().totalSupply(),
            pool.getMinHealthFactorForBorrow(),
            pool.getCurrentLiquidationRatio(),
            pool.getCurrentCollateralRatio(),
            pool.cooldownPeriod(),
            pool.loanFee(),
            pool.stabilityFee(),
            WAD,
            PRECISION
        );
    }

    function getUserPoolData(address user) public view returns (UserPoolData memory data) {
        IPool pool = provider().pool();

        data.tokensOnWallet = getTokensBalances(user, pool.collateralTokens());

        if (!pool.isPositionExist(user)) return data;

        data.position = pool.getPosition(user);
        data.healthFactor = getHealthFactor(user);
        data.totalXUSDDebt = totalXUSDDebt(user);
        data.debtSharesBalance = pool.debtShares().balanceOf(user);
        data.collateralValue = pool.totalPositionCollateralValue(data.position.collaterals);
        data.maxXUSDBorrow = maxXUSDBorrow(user);
    }

    /* ======== POOL MATH ======== */

    function getHealthFactor(address user) public view returns (uint256) {
        return provider().pool().getHealthFactor(user);
    }

    function reCalcHf(address user, ReCalcHfParams memory params) public view returns (uint256) {
        IPool pool = provider().pool();

        IPool.Position memory position = pool.getPosition(user);

        uint256 index = position.collaterals.indexOf(params.collateralToken);

        if (params.collateralAmount > 0) {
            if (index == INDEX_NOT_FOUND) {
                position = _copyPositionAndPushCollateral(position, params);
            } else {
                position.collaterals[uint8(index)].amount += uint256(params.collateralAmount);
            }
        } else if (params.collateralAmount < 0) {
            position.collaterals[index].amount -=
                type(uint256).max - uint256(params.collateralAmount) + 1;
        }

        uint256 shares = pool.debtShares().balanceOf(user) + pool.calculateStabilityFee(user);

        if (params.debtAmount > 0) {
            shares += pool.convertToShares(uint256(params.debtAmount));
        } else if (params.debtAmount < 0) {
            shares -= pool.convertToShares(type(uint256).max - uint256(params.debtAmount) + 1);
        }

        return pool.calculateHealthFactor(position.collaterals, shares);
    }

    function totalXUSDDebt(address user) public view returns (uint256) {
        IPool pool = provider().pool();
        return pool.convertToAssets(pool.debtShares().balanceOf(user));
    }

    function maxXUSDBorrow(address user) public view returns (uint256 maxBorrow) {
        IPool pool = provider().pool();

        IPool.Position memory position = pool.getPosition(user);

        uint256 collateralValue = pool.totalPositionCollateralValue(position.collaterals);

        uint256 _totalDebt = pool.convertToAssets(pool.debtShares().balanceOf(user));

        uint256 maxBorrowWithoutDebt = (
            (
                (
                    ((collateralValue * 10 ** provider().xusd().decimals()) * PRECISION)
                        / pool.getCurrentCollateralRatio()
                )
            ) / WAD
        );

        maxBorrow = maxBorrowWithoutDebt > _totalDebt ? maxBorrowWithoutDebt - _totalDebt : 0;
    }

    function maxWithdraw(address user, address token)
        public
        view
        returns (uint256 tokenAmount, uint256 dollarAmountInTokenDecimals)
    {
        IPool pool = provider().pool();
        IOracleAdapter oracle = provider().oracle();

        uint256 _tokenPrice = oracle.getPrice(token);

        IPool.Position memory position = pool.getPosition(user);

        uint256 index = position.collaterals.indexOf(token);

        uint256 _totalCollateralValue = pool.totalPositionCollateralValue(position.collaterals);

        uint256 _totalXUSDDebt = pool.convertToAssets(pool.debtShares().balanceOf(user));
        uint256 _collateralRatio = pool.getCurrentCollateralRatio();

        if (_totalCollateralValue <= (_totalXUSDDebt * _collateralRatio) / PRECISION) return (0, 0);

        uint256 _maxWithdrawAmount =
            _totalCollateralValue - ((_totalXUSDDebt * _collateralRatio) / PRECISION); // _maxAllowedToWithdrawInDollars

        uint256 _collateralValue = pool.calculateCollateralValue(
            position.collaterals[uint8(index)].token, position.collaterals[uint8(index)].amount
        );

        uint256 tokenDecimalsDelta = 10 ** (18 - IERC20Metadata(token).decimals());

        dollarAmountInTokenDecimals =
            _maxWithdrawAmount < _collateralValue ? _maxWithdrawAmount : _collateralValue;

        tokenAmount = (((dollarAmountInTokenDecimals * oracle.precision()) / _tokenPrice))
            / tokenDecimalsDelta;

        dollarAmountInTokenDecimals /= tokenDecimalsDelta;
    }

    /// @notice Find the liquidation opportunity for the users
    /// @notice This is gas efficient way to find the liquidation opportunity for the users
    /// @param users The users to find the liquidation opportunity for
    /// @return token The tokens to liquidate
    /// @return shares The shares to liquidate
    function findLiquidationOpportunity(address[] calldata users)
        external
        view
        returns (address[] memory token, uint256[] memory shares)
    {
        IPool pool = provider().pool();
        IOracleAdapter oracle = provider().oracle();

        uint256 pricePerShare = pool.pricePerShare();

        uint256 xusdPrecision = 10 ** provider().xusd().decimals();
        uint256 oraclePrecision = oracle.precision();

        uint256 liquidationRatio = pool.getCurrentLiquidationRatio();

        token = new address[](users.length);
        shares = new uint256[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            IPool.Position memory position = pool.getPosition(user);

            uint256 positionShares = pool.debtShares().balanceOf(user);

            {
                if (positionShares == 0) continue;

                uint256 hf = _calculateHealthFactor(
                    position.collaterals,
                    _convertToAssets(positionShares, pricePerShare, xusdPrecision),
                    liquidationRatio,
                    oracle,
                    oraclePrecision
                );

                if (hf >= WAD) continue;
            }

            for (uint256 j = 0; j < position.collaterals.length; j++) {
                IPool.CollateralData memory collateral = position.collaterals[j];

                uint256 maxSharesToLiquidate = _getMaxSharesToLiquidate(
                    collateral,
                    oracle.getPrice(collateral.token),
                    positionShares,
                    pricePerShare,
                    xusdPrecision,
                    oraclePrecision
                );

                if (maxSharesToLiquidate > shares[i]) {
                    shares[i] = maxSharesToLiquidate;
                    token[i] = collateral.token;
                }
            }
        }
    }

    function _convertToAssets(uint256 shares, uint256 pricePerShare, uint256 xusdPrecision)
        internal
        pure
        returns (uint256 assets)
    {
        assets = (shares * pricePerShare * xusdPrecision) / (WAD * WAD);
    }

    function _convertToShares(uint256 assets, uint256 pricePerShare, uint256 xusdPrecision)
        internal
        pure
        returns (uint256 shares)
    {
        shares = (assets * WAD * WAD) / (pricePerShare * xusdPrecision);
    }

    function _getMaxSharesToLiquidate(
        IPool.CollateralData memory collateral,
        uint256 collateralPrice,
        uint256 positionShares,
        uint256 pricePerShare,
        uint256 xusdPrecision,
        uint256 oraclePrecision
    ) internal view returns (uint256 shares) {
        IPool pool = provider().pool();

        uint256 bonusPoint = pool.liquidationBonusPercentagePoint();
        uint256 penaltyPoint = pool.liquidationPenaltyPercentagePoint();

        uint256 deductions = (collateral.amount * (bonusPoint + penaltyPoint)) / PRECISION;

        uint256 collateralAmountToLiquidate = collateral.amount - deductions;

        collateralAmountToLiquidate = (collateralAmountToLiquidate / 1000) * 1023; // TODO: refactor this

        uint256 xusdAmount = (collateralAmountToLiquidate * collateralPrice) / oraclePrecision;

        xusdAmount *= xusdPrecision / 10 ** IERC20Metadata(collateral.token).decimals();

        shares = _convertToShares(xusdAmount, pricePerShare, xusdPrecision);

        if (shares * 2 > positionShares) return positionShares / 2;
    }

    function _calculateHealthFactor(
        IPool.CollateralData[] memory collateralData,
        uint256 totalDebt,
        uint256 liquidationRatio,
        IOracleAdapter oracle,
        uint256 oraclePrecision
    ) internal view returns (uint256 hf) {
        uint256 totalUsdCollateralValue =
            _totalPositionCollateralValue(collateralData, oracle, oraclePrecision);

        hf = (WAD * totalUsdCollateralValue) / ((totalDebt * liquidationRatio) / PRECISION);
    }

    function _totalPositionCollateralValue(
        IPool.CollateralData[] memory collaterals,
        IOracleAdapter oracle,
        uint256 oraclePrecision
    ) internal view returns (uint256 collateralValue) {
        for (uint256 i = 0; i < collaterals.length; i++) {
            uint256 collateralAmount = (collaterals[i].amount * WAD)
                / (10 ** IERC20Metadata(collaterals[i].token).decimals());

            uint256 collateralPrice = oracle.getPrice(collaterals[i].token);

            collateralValue += (collateralAmount * collateralPrice) / oraclePrecision;
        }
    }

    /* ======== MISC ======== */

    function getTokensBalances(address user, address[] memory tokens)
        public
        view
        returns (Token[] memory data)
    {
        data = new Token[](tokens.length);

        IOracleAdapter oracle = provider().oracle();

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20Metadata token = IERC20Metadata(tokens[i]);

            data[i] = Token(
                tokens[i],
                token.name(),
                token.symbol(),
                token.decimals(),
                oracle.getPrice(tokens[i]),
                token.balanceOf(user)
            );
        }
    }

    function _copyPositionAndPushCollateral(
        IPool.Position memory position,
        ReCalcHfParams memory params
    ) internal pure returns (IPool.Position memory) {
        IPool.Position memory newPosition = IPool.Position(
            new IPool.CollateralData[](position.collaterals.length + 1),
            position.lastBorrowTimestamp,
            position.lastChargedFeeTimestamp
        );

        for (uint256 i = 0; i < position.collaterals.length; i++) {
            newPosition.collaterals[i] = position.collaterals[i];
        }

        newPosition.collaterals[newPosition.collaterals.length - 1] =
            IPool.CollateralData(params.collateralToken, uint256(params.collateralAmount));

        return newPosition;
    }

    function _afterInitialize() internal override {
        _registerInterface(type(IPoolDataProvider).interfaceId);
    }
}
