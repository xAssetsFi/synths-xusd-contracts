// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Calculations} from "./_Calculations.sol";

import {ISynth} from "src/interface/platforms/synths/ISynth.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {PoolArrayLib} from "src/lib/PoolArrayLib.sol";
import {Math as OZMathLib} from "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract Position is Calculations {
    using SafeERC20 for IERC20;
    using SafeERC20 for ISynth;
    using PoolArrayLib for CollateralData[];

    function _supply(address token, uint256 amount) internal noZeroUint(amount) {
        Position storage position = _positions[msg.sender];

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        int8 index = position.collaterals.getIndex(token);

        if (index == -1) {
            position.collaterals.push(CollateralData(token, amount));
        } else {
            position.collaterals[uint8(index)].amount += amount;
        }

        _checkHealthFactor(msg.sender, WAD);

        emit Supply(msg.sender, token, amount);
    }

    function _withdraw(address token, uint256 amount, address to) internal noZeroUint(amount) {
        Position storage position = _positions[msg.sender];

        int8 index = position.collaterals.getIndex(token);
        if (index == -1) revert NotCollateralToken();

        position.collaterals[uint8(index)].amount -= amount;
        IERC20(token).safeTransfer(to, amount);

        if (position.collaterals[uint8(index)].amount == 0) {
            position.collaterals.remove(token);
        }

        _checkHealthFactor(msg.sender, getMinHealthFactorForBorrow());

        emit Withdraw(msg.sender, token, amount, to, !isPositionExist(msg.sender));
    }

    function _repay(uint256 shares) internal noZeroUint(shares) {
        uint256 xusdAmount = convertToAssets(shares);

        debtShares.burn(msg.sender, shares);

        provider().xusd().burn(msg.sender, xusdAmount);

        _checkHealthFactor(msg.sender, WAD);

        emit Repay(msg.sender, xusdAmount, debtShares.balanceOf(msg.sender));
    }

    function _borrow(uint256 xusdAmount, address to) internal noZeroUint(xusdAmount) {
        debtShares.mint(msg.sender, convertToShares(xusdAmount));

        _checkHealthFactor(msg.sender, getMinHealthFactorForBorrow());

        ISynth xusd = provider().xusd();

        uint256 fee = OZMathLib.mulDiv(xusdAmount, loanFee, PRECISION);

        xusd.mint(to, xusdAmount - fee);
        xusd.mint(feeReceiver, fee);

        _positions[msg.sender].lastBorrowTimestamp = block.timestamp;

        emit Borrow(msg.sender, xusdAmount, to);
    }

    function _liquidate(address positionOwner, address collateralToken, uint256 shares, address to)
        internal
        noZeroUint(shares)
    {
        Position storage position = _positions[positionOwner];

        ISynth xusd = provider().xusd();
        uint256 xusdAmount = convertToAssets(shares);

        debtShares.burn(positionOwner, shares);
        xusd.burn(msg.sender, xusdAmount);

        (uint256 base, uint256 bonus, uint256 penalty) =
            calculateDeductionsWhileLiquidation(collateralToken, xusdAmount);

        uint8 i = uint8(position.collaterals.getIndex(collateralToken));

        if (position.collaterals[i].amount < base + bonus + penalty) {
            revert NotEnoughCollateral(base + bonus + penalty, position.collaterals[i].amount);
        }

        position.collaterals[i].amount -= base + bonus + penalty;
        IERC20(collateralToken).safeTransfer(to, base + bonus);
        IERC20(collateralToken).safeTransfer(feeReceiver, penalty);

        if (position.collaterals[i].amount == 0) {
            position.collaterals.remove(collateralToken);
        }

        emit Liquidate(positionOwner, collateralToken, shares, to);
    }

    /* ======== UTILS ======== */

    function getHealthFactor(address user) public view isPosExist(user) returns (uint256) {
        return calculateHealthFactor(
            _positions[user].collaterals, debtShares.balanceOf(user) + calculateStabilityFee(user)
        );
    }

    function _checkHealthFactor(address positionOwner, uint256 minHealthFactor) internal view {
        if (!isPositionExist(positionOwner)) return;

        uint256 healthFactor = getHealthFactor(positionOwner);

        if (healthFactor < minHealthFactor) {
            revert HealthFactorTooLow(healthFactor, minHealthFactor);
        }
    }

    function isPositionExist(address user) public view returns (bool) {
        return _positions[user].collaterals.length > 0;
    }

    modifier chargeStabilityFee(address positionOwner) {
        Position storage position = _positions[positionOwner];

        uint256 stabilityFeeShares = calculateStabilityFee(positionOwner);

        position.lastChargedFeeTimestamp = block.timestamp;

        if (stabilityFeeShares > 0) {
            debtShares.mint(positionOwner, stabilityFeeShares);

            provider().xusd().mint(feeReceiver, convertToAssets(stabilityFeeShares));
        }

        _;
    }

    modifier isPosExist(address user) {
        if (!isPositionExist(user)) revert PositionNotExists();
        _;
    }
}
