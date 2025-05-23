// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IPool} from "src/interface/IPool.sol";
import {WETHGateway} from "./modules/pool/_WETHGateway.sol";
import {CalculationsInitParams} from "./modules/pool/_Calculations.sol";

import {ArrayLib, INDEX_NOT_FOUND} from "src/lib/ArrayLib.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Pool contract
/// @dev Inheritance:
/// Pool -> WETHGateway -> Position -> Calculations -> State -> UUPSImplementation -> Base
contract Pool is WETHGateway {
    using ArrayLib for address[];

    function initialize(
        address _provider,
        address _weth,
        address _debtShares,
        CalculationsInitParams memory params
    ) public initializer {
        __Calculations_init(Ownable(_provider).owner(), _debtShares, params);
        __ProviderKeeper_init(_provider);
        __WETHGateway_init(_weth);

        _registerInterface(type(IPool).interfaceId);
    }

    function supply(address token, uint256 amount)
        external
        nonReentrant
        noPaused
        isCollateral(token)
        chargeStabilityFee(msg.sender)
    {
        _supply(token, amount);
    }

    function withdraw(address token, uint256 amount, address to)
        external
        nonReentrant
        noPaused
        isPosExist(msg.sender)
        chargeStabilityFee(msg.sender)
        isCollateral(token)
    {
        _withdraw(token, amount, to);
    }

    function borrow(uint256 xusdAmount, uint256 maxDebtShares, address to)
        public
        override
        nonReentrant
        noPaused
        isPosExist(msg.sender)
        chargeStabilityFee(msg.sender)
    {
        _borrow(xusdAmount, maxDebtShares, to);
    }

    function repay(uint256 shares, uint256 maxXusdAmount)
        external
        nonReentrant
        noPaused
        isPosExist(msg.sender)
        chargeStabilityFee(msg.sender)
        isCooldown(_positions[msg.sender].lastBorrowTimestamp)
    {
        uint256 sharesBalance = debtShares.balanceOf(msg.sender);
        uint256 amountToRepay = shares;

        if (shares > sharesBalance) amountToRepay = sharesBalance;

        _repay(amountToRepay, maxXusdAmount);

        if (shares == INDEX_NOT_FOUND) {
            Position memory position = _positions[msg.sender];

            for (uint256 i = 0; i < position.collaterals.length; i++) {
                _withdraw(position.collaterals[i].token, position.collaterals[i].amount, msg.sender);
            }
        }
    }

    function liquidate(
        address positionOwner,
        address token,
        uint256 minTokenAmount,
        uint256 shares,
        address to
    ) external noPaused isCollateral(token) chargeStabilityFee(positionOwner) nonReentrant {
        if (getHealthFactor(positionOwner) >= WAD) revert PositionHealthy();

        uint256 positionShares = debtShares.balanceOf(positionOwner);

        if (shares * 2 > positionShares) {
            revert LiquidationAmountTooHigh(shares, positionShares / 2);
        }

        _liquidate(positionOwner, token, minTokenAmount, shares, to);
    }

    function supplyAndBorrow(
        address token,
        uint256 supplyAmount,
        uint256 borrowXusdAmount,
        uint256 maxDebtShares,
        address borrowTo
    ) external noPaused isCollateral(token) nonReentrant chargeStabilityFee(msg.sender) {
        _supply(token, supplyAmount);
        _borrow(borrowXusdAmount, maxDebtShares, borrowTo);
    }

    function getPosition(address user) external view isPosExist(user) returns (Position memory) {
        return _positions[user];
    }

    function collateralTokens() external view returns (address[] memory) {
        return _collateralTokens;
    }

    /* ======== Admin Functions ======== */

    function addCollateralToken(address token) external onlyOwner {
        if (isCollateralToken[token]) revert CollateralTokenAlreadyExists();

        _collateralTokens.push(token);
        isCollateralToken[token] = true;
        emit CollateralTokenAdded(token);
    }

    function removeCollateralToken(address token) external onlyOwner {
        bool removed = _collateralTokens.remove(token);
        if (!removed) revert CollateralTokenNotFound();

        isCollateralToken[token] = false;
        emit CollateralTokenRemoved(token);
    }

    function setCollateralRatio(uint32 ratio, uint64 duration) external onlyOwner {
        ratioAdjustments["collateral"] = RatioAdjustment({
            targetRatio: ratio,
            startRatio: getCurrentCollateralRatio(),
            startTime: uint64(block.timestamp),
            duration: duration
        });
        emit CollateralRatioAdjustmentStarted(ratio, duration);
    }

    function setLiquidationRatio(uint32 ratio, uint64 duration)
        external
        onlyOwner
        greaterThanPrecision(ratio)
    {
        ratioAdjustments["liquidation"] = RatioAdjustment({
            targetRatio: ratio,
            startRatio: getCurrentLiquidationRatio(),
            startTime: uint64(block.timestamp),
            duration: duration
        });
        emit LiquidationRatioAdjustmentStarted(ratio, duration);
    }

    function setLiquidationPenaltyPercentagePoint(uint32 percentagePoint)
        external
        validateLiquidationDeductions
        onlyOwner
    {
        liquidationPenaltyPercentagePoint = percentagePoint;
        emit LiquidationPenaltyPercentagePointSet(percentagePoint);
    }

    function setLiquidationBonusPercentagePoint(uint32 percentagePoint)
        external
        validateLiquidationDeductions
        onlyOwner
    {
        liquidationBonusPercentagePoint = percentagePoint;
        emit LiquidationBonusPercentagePointSet(percentagePoint);
    }

    function setLoanFee(uint32 fee) external onlyOwner lessThanPrecision(fee) {
        loanFee = fee;
        emit LoanFeeSet(fee);
    }

    function setStabilityFee(uint32 fee) external onlyOwner lessThanPrecision(fee) {
        stabilityFee = fee;
        emit StabilityFeeSet(fee);
    }

    function setCooldownPeriod(uint32 period) external onlyOwner {
        cooldownPeriod = period;
        emit CooldownPeriodSet(period);
    }

    function setFeeReceiver(address newFeeReceiver)
        external
        onlyOwner
        noZeroAddress(newFeeReceiver)
    {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverSet(newFeeReceiver);
    }

    /* ======== MODIFIERS ======== */

    modifier isCooldown(uint256 lastBorrowTimestamp) {
        if (block.timestamp - lastBorrowTimestamp < cooldownPeriod) {
            revert Cooldown();
        }

        _;
    }
}
