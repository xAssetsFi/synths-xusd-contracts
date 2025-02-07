// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {State} from "./_State.sol";

import {IOracleAdapter} from "src/interface/IOracleAdapter.sol";
import {IPlatform} from "src/interface/platforms/IPlatform.sol";
import {IDebtShares} from "src/interface/IDebtShares.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

struct CalculationsInitParams {
    uint32 collateralRatio;
    uint32 liquidationRatio;
    uint32 liquidationPenaltyPercentagePoint;
    uint32 liquidationBonusPercentagePoint;
    uint32 loanFee;
    uint32 stabilityFee;
    uint32 cooldownPeriod;
}

abstract contract Calculations is State {
    function __Calculations_init(
        address _feeReceiver,
        address _debtShares,
        CalculationsInitParams memory params
    )
        internal
        onlyInitializing
        noZeroAddress(_feeReceiver)
        noZeroAddress(_debtShares)
        validInterface(_debtShares, type(IDebtShares).interfaceId)
    {
        collateralRatio = params.collateralRatio;
        liquidationRatio = params.liquidationRatio;
        stabilityFee = params.stabilityFee;
        loanFee = params.loanFee;
        cooldownPeriod = params.cooldownPeriod;
        liquidationPenaltyPercentagePoint = params.liquidationPenaltyPercentagePoint;
        liquidationBonusPercentagePoint = params.liquidationBonusPercentagePoint;

        feeReceiver = _feeReceiver;
        debtShares = IDebtShares(_debtShares);
    }

    function calculateHealthFactor(CollateralData[] memory collateralData, uint256 shares)
        public
        view
        returns (uint256 hf)
    {
        if (shares == 0) return type(uint256).max;

        uint256 totalUsdCollateralValue = totalPositionCollateralValue(collateralData);

        uint256 totalDebt = convertToAssets(shares);

        hf = Math.mulDiv(totalUsdCollateralValue, WAD, (totalDebt * liquidationRatio) / PRECISION);
    }

    function totalPositionCollateralValue(CollateralData[] memory collaterals)
        public
        view
        returns (uint256 collateralValue)
    {
        for (uint256 i = 0; i < collaterals.length; i++) {
            collateralValue += calculateCollateralValue(collaterals[i].token, collaterals[i].amount);
        }
    }

    function calculateCollateralValue(address token, uint256 amount)
        public
        view
        returns (uint256 collateralValue)
    {
        IOracleAdapter oracle = provider().oracle();

        uint256 collateralAmount = (amount * WAD) / (10 ** IERC20Metadata(token).decimals());

        uint256 collateralPrice = oracle.getPrice(token);

        collateralValue = Math.mulDiv(collateralAmount, collateralPrice, oracle.precision());
    }

    function totalFundsOnPlatforms() public view returns (uint256 tf) {
        IPlatform[] memory platforms = provider().platforms();

        for (uint256 i = 0; i < platforms.length; i++) {
            tf += platforms[i].totalFunds();
        }
    }

    function pricePerShare() public view returns (uint256 pps) {
        uint256 tf = totalFundsOnPlatforms();
        uint256 ts = debtShares.totalSupply();

        if (tf == 0 || ts == 0) return WAD;

        pps = Math.mulDiv(tf, WAD, ts);
    }

    function getMinHealthFactorForBorrow() public view returns (uint256 hf) {
        hf = Math.mulDiv(collateralRatio, WAD, liquidationRatio);
    }

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        uint256 xusdPrecision = 10 ** provider().xusd().decimals();
        assets = Math.mulDiv(shares, pricePerShare() * xusdPrecision, WAD * WAD);
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        uint256 xusdPrecision = 10 ** provider().xusd().decimals();
        shares = Math.mulDiv(assets, WAD * WAD, pricePerShare() * xusdPrecision);
    }

    function calculateDeductionsWhileLiquidation(address token, uint256 xusdAmount)
        public
        view
        returns (uint256 base, uint256 bonus, uint256 penalty)
    {
        uint256 tokenDecimalsDelta = 10 ** (18 - IERC20Metadata(token).decimals());

        IOracleAdapter oracle = provider().oracle();

        uint256 collateralPrice = oracle.getPrice(token);
        uint256 oraclePrecision = oracle.precision();

        // amount in collateral token, equivalent to amountXUSDToRepay
        base = Math.mulDiv(xusdAmount, oraclePrecision, collateralPrice) / tokenDecimalsDelta;

        // bonus for liquidator in collateral token
        bonus = Math.mulDiv(base, liquidationBonusPercentagePoint, tokenDecimalsDelta) / PRECISION;

        // penalty to platform due liquidation in collateral token
        penalty =
            Math.mulDiv(base, liquidationPenaltyPercentagePoint, tokenDecimalsDelta) / PRECISION;
    }

    function calculateStabilityFee(address positionOwner)
        public
        view
        returns (uint256 stabilityFeeShares)
    {
        Position storage position = _positions[positionOwner];

        // 0 is possible for empty user's position
        if (
            position.lastChargedFeeTimestamp == block.timestamp || position.lastBorrowTimestamp == 0
        ) return 0;

        uint256 passedTime = block.timestamp - position.lastChargedFeeTimestamp;

        // userDebtShares * stabilityFee * passedTime / (1 year * PRECISION)
        stabilityFeeShares = Math.mulDiv(
            debtShares.balanceOf(positionOwner), stabilityFee * passedTime, 365 days * PRECISION
        );
    }
}
