// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IPool} from "src/interface/IPool.sol";
import {WETHGateway} from "./modules/_WETHGateway.sol";

import {ArrayLib} from "src/lib/ArrayLib.sol";

import {CalculationsInitParams} from "./modules/_Calculations.sol";

/// @notice Pool contract
/// @dev Inheritance:
/// Pool -> WETHGateway -> Position -> Calculations -> State -> UUPSProxy -> Base
contract Pool is WETHGateway {
    function initialize(
        address _owner,
        address _provider,
        address _weth,
        address _debtShares,
        CalculationsInitParams memory params
    ) public initializer {
        __Calculations_init(_owner, _debtShares, params);
        __UUPSProxy_init(_owner, _provider);
        __WETHGateway_init(_weth);
        _afterInitialize();
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

    function borrow(uint256 xusdAmount, address to)
        public
        override
        nonReentrant
        noPaused
        isPosExist(msg.sender)
        chargeStabilityFee(msg.sender)
    {
        _borrow(xusdAmount, to);
    }

    function repay(uint256 shares)
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

        _repay(amountToRepay);

        if (shares == type(uint256).max) {
            Position memory position = _positions[msg.sender];

            for (uint256 i = 0; i < position.collaterals.length; i++) {
                _withdraw(position.collaterals[i].token, position.collaterals[i].amount, msg.sender);
            }
        }
    }

    function liquidate(address positionOwner, address token, uint256 shares, address to)
        external
        noPaused
        isPosExist(positionOwner)
        isCollateral(token)
        chargeStabilityFee(positionOwner)
        nonReentrant
    {
        if (getHealthFactor(positionOwner) >= WAD) revert PositionHealthy();

        uint256 positionShares = debtShares.balanceOf(positionOwner);

        if (shares * 2 > positionShares) {
            revert LiquidationAmountTooHigh(shares, positionShares / 2);
        }

        _liquidate(positionOwner, token, shares, to);
    }

    function supplyAndBorrow(
        address token,
        uint256 supplyAmount,
        uint256 borrowXusdAmount,
        address borrowTo
    ) external noPaused isCollateral(token) nonReentrant chargeStabilityFee(msg.sender) {
        _supply(token, supplyAmount);
        _borrow(borrowXusdAmount, borrowTo);
    }

    function getPosition(address user) external view isPosExist(user) returns (Position memory) {
        return _positions[user];
    }

    function collateralTokens() external view returns (address[] memory) {
        return _collateralTokens;
    }

    /* ======== Admin Functions ======== */

    function addCollateralToken(address token) external onlyOwner {
        _collateralTokens.push(token);
        isCollateralToken[token] = true;
        emit CollateralTokenAdded(token);
    }

    function removeCollateralToken(address token) external onlyOwner {
        ArrayLib.remove(_collateralTokens, token);
        isCollateralToken[token] = false;
        emit CollateralTokenRemoved(token);
    }

    function setCollateralRatio(uint32 ratio) external onlyOwner {
        collateralRatio = ratio;
        emit CollateralRatioSet(ratio);
    }

    function setLiquidationRatio(uint32 ratio) external onlyOwner {
        liquidationRatio = ratio;
        emit LiquidationRatioSet(ratio);
    }

    function setLiquidationPenaltyPercentagePoint(uint32 percentagePoint) external onlyOwner {
        liquidationPenaltyPercentagePoint = percentagePoint;
        emit LiquidationPenaltyPercentagePointSet(percentagePoint);
    }

    function setLiquidationBonusPercentagePoint(uint32 percentagePoint) external onlyOwner {
        liquidationBonusPercentagePoint = percentagePoint;
        emit LiquidationBonusPercentagePointSet(percentagePoint);
    }

    function setLoanFee(uint32 fee) external onlyOwner {
        loanFee = fee;
        emit LoanFeeSet(fee);
    }

    function setStabilityFee(uint32 fee) external onlyOwner {
        stabilityFee = fee;
        emit StabilityFeeSet(fee);
    }

    function setCooldownPeriod(uint32 period) external onlyOwner {
        cooldownPeriod = period;
        emit CooldownPeriodSet(period);
    }

    /* ======== MODIFIERS ======== */

    modifier isCooldown(uint256 lastBorrowTimestamp) {
        if (block.timestamp - lastBorrowTimestamp < cooldownPeriod) {
            revert Cooldown();
        }

        _;
    }

    function initialize(address, address) public pure override {
        revert DeprecatedInitializer();
    }

    function _afterInitialize() internal override {
        _registerInterface(type(IPool).interfaceId);
    }
}
