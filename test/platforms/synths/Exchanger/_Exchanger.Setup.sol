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

    // function _swap(address synthIn, address synthOut, uint256 amountIn, uint256 minAmountOut)
    //     internal
    // {
    //     address t = address(this);

    //     uint256 balanceThisSynthInBefore = ISynth(synthIn).balanceOf(t);
    //     uint256 balanceExchangerSynthInBefore = ISynth(synthOut).balanceOf(address(exchanger));

    //     exchanger.swap{value: exchanger.getSwapFeeForSettle()}(
    //         synthIn, synthOut, amountIn, minAmountOut, t
    //     );

    //     uint256 balanceThisSynthInAfter = ISynth(synthIn).balanceOf(t);
    //     uint256 balanceExchangerSynthInAfter = ISynth(synthOut).balanceOf(address(exchanger));

    //     // assertEq(balanceThisSynthInBefore - balanceThisSynthInAfter, amountIn);
    //     // assertEq(balanceExchangerSynthInAfter - balanceExchangerSynthInBefore, amountIn);

    //     // skip(exchanger.settlementDelay());

    //     // uint256 balanceThisSynthOutBefore = ISynth(synthOut).balanceOf(t);

    //     // exchanger.finishSwap(t, synthOut, t);

    //     // uint256 balanceThisSynthOutAfter = ISynth(synthOut).balanceOf(t);
    //     // balanceExchangerSynthInAfter = ISynth(synthIn).balanceOf(address(exchanger));

    //     // assertEq(balanceThisSynthOutAfter - balanceThisSynthOutBefore, amountOut);
    //     // assertEq(balanceExchangerSynthInAfter, balanceExchangerSynthInBefore);
    // }

    // function _finishSwap(address user, address synth) internal {
    //     IExchanger.PendingSwap memory pendingSwap = exchanger.getPendingSwap(user, synth);

    //     address synthIn = pendingSwap.swaps[0].synthIn;
    //     address synthOut = pendingSwap.swaps[0].synthOut;
    //     uint256 amountIn = pendingSwap.swaps[0].amountIn;

    //     uint256 amountOut = exchanger.previewSwap(synthIn, synthOut, amountIn);

    //     skip(exchanger.settlementDelay());
    //     uint256 balanceBeforeSettle = address(this).balance;
    //     uint256 balanceThisSynthOutBefore = ISynth(synthOut).balanceOf(user);

    //     exchanger.finishSwap(user, synth, user);

    //     uint256 balanceThisSynthOutAfter = ISynth(synthOut).balanceOf(user);
    //     uint256 balanceExchangerSynthInAfter = ISynth(synthIn).balanceOf(address(exchanger));

    //     // assertEq(balanceThisSynthOutAfter - balanceThisSynthOutBefore, amountOut);
    //     // assertEq(balanceExchangerSynthInAfter, 0);
    //     assertGe(address(this).balance, balanceBeforeSettle);
    // }
}
