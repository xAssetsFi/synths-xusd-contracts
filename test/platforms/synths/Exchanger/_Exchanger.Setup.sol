// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";
import {ISynth} from "src/interface/platforms/synths/ISynth.sol";
import {IExchanger} from "src/interface/platforms/synths/IExchanger.sol";

contract ExchangerSetup is Setup {
    address feeReceiver = address(0x99999);

    uint256 amountSupplied = 1000 ether;
    uint256 amountBorrowed = 50 ether;

    function _afterSetup() internal override {
        super._afterSetup();

        pool.supply(address(usdc), amountSupplied);
        pool.borrow(amountBorrowed, address(this));

        xusd.approve(address(exchanger), type(uint256).max);

        exchanger.setFeeReceiver(feeReceiver);
    }

    function _swap(address synthIn, address synthOut, uint256 amountIn) internal {
        address t = address(this);

        uint256 balanceSynthInBefore = ISynth(synthIn).balanceOf(t);
        uint256 balanceSynthOutBefore = ISynth(synthOut).balanceOf(t);

        uint256 amountOut =
            exchanger.swap{value: exchanger.getSwapFeeForSettle()}(synthIn, synthOut, amountIn, t);
        uint256 balanceSynthInAfter = ISynth(synthIn).balanceOf(t);
        uint256 balanceSynthOutAfter = ISynth(synthOut).balanceOf(t);

        assertEq(balanceSynthInBefore - balanceSynthInAfter, amountIn);
        assertEq(balanceSynthOutAfter - balanceSynthOutBefore, amountOut);
    }

    receive() external payable {}
}
