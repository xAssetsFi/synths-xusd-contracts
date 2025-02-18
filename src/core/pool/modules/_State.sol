// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IDebtShares} from "src/interface/IDebtShares.sol";
import {UUPSProxy} from "src/common/_UUPSProxy.sol";

import {IPool} from "src/interface/IPool.sol";

import {IWETH} from "src/interface/external/IWETH.sol";

abstract contract State is UUPSProxy, IPool {
    IWETH public weth;

    IDebtShares public debtShares;

    address public feeReceiver;

    uint32 public collateralRatio;
    uint32 public liquidationRatio;

    uint32 public liquidationPenaltyPercentagePoint;
    uint32 public liquidationBonusPercentagePoint;

    uint32 public loanFee;
    uint32 public stabilityFee;

    /// @notice Cooldown period to execute repay after borrow
    uint32 public cooldownPeriod;

    mapping(address user => Position) internal _positions;

    mapping(address token => bool isCollateral) public isCollateralToken;
    address[] internal _collateralTokens;
}
