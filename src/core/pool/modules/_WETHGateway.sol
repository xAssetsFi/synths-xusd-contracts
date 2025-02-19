// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Position} from "./_Position.sol";

import {IWETH} from "src/interface/external/IWETH.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract WETHGateway is Position, ReentrancyGuard {
    using SafeERC20 for IWETH;

    function __WETHGateway_init(address _weth) internal onlyInitializing noZeroAddress(_weth) {
        weth = IWETH(_weth);
    }

    function supplyETH() public payable nonReentrant noPaused chargeStabilityFee(msg.sender) {
        _wrapETH(msg.value);
        _supply(address(weth), msg.value);
    }

    function withdrawETH(uint256 amount, address to)
        public
        nonReentrant
        noPaused
        isPosExist(msg.sender)
        chargeStabilityFee(msg.sender)
    {
        _withdraw(address(weth), amount, address(this));

        weth.withdraw(amount);
        (bool success,) = to.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function supplyETHAndBorrow(uint256 borrowXusdAmount, uint256 maxDebtShares, address borrowTo)
        public
        payable
        noPaused
        nonReentrant
        chargeStabilityFee(msg.sender)
    {
        _wrapETH(msg.value);
        _supply(address(weth), msg.value);
        _borrow(borrowXusdAmount, maxDebtShares, borrowTo);
    }

    function _wrapETH(uint256 amount) internal {
        weth.deposit{value: amount}();
        weth.safeTransfer(msg.sender, amount);
    }

    /* ======== Modifiers ======== */

    modifier isCollateral(address token) {
        if (!isCollateralToken[token]) revert NotCollateralToken();
        _;
    }

    receive() external payable {}
}
