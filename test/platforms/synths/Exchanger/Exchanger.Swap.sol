// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Exchanger.Setup.sol";

contract Swap is ExchangerSetup {
    function testFuzz_swap(uint256 amountIn) public {
        vm.assume(amountIn > fuzzingDust);
        vm.assume(amountIn <= amountBorrowed);

        _swap(address(xusd), address(gold), amountIn, 0);
        _finishSwap(address(this), address(gold));
    }

    function testFuzz_chargingFee_synthInEqXUSD(uint256 amountIn) public {
        vm.assume(amountIn > 1e4);
        vm.assume(amountIn <= amountBorrowed);

        uint256 feeReceiverBalanceBefore = xusd.balanceOf(feeReceiver);
        // uint256 debtSharesBalanceBefore = xusd.balanceOf(address(debtShares));

        _swap(address(xusd), address(gold), amountIn);
        _finishSwap(address(this), address(gold));

        uint256 feeReceiverBalanceAfter = xusd.balanceOf(feeReceiver);
        // uint256 debtSharesBalanceAfter = xusd.balanceOf(address(debtShares));

        assertGt(feeReceiverBalanceAfter, feeReceiverBalanceBefore);
        // assertGt(debtSharesBalanceAfter, debtSharesBalanceBefore);
    }

    function testFuzz_chargingFee_synthInNotEqXUSD(uint256 amountIn) public {
        vm.assume(amountIn > 1e4);
        vm.assume(amountIn <= 1e50);

        deal(address(gold), address(this), amountIn);
        gold.approve(address(exchanger), amountIn);

        uint256 feeReceiverBalanceBefore = xusd.balanceOf(feeReceiver);
        uint256 debtSharesBalanceBefore = xusd.balanceOf(address(debtShares));

        _swap(address(gold), address(tesla), amountIn, 0);
        _finishSwap(address(this), address(tesla));

        uint256 feeReceiverBalanceAfter = xusd.balanceOf(feeReceiver);
        uint256 debtSharesBalanceAfter = xusd.balanceOf(address(debtShares));

        assertGt(feeReceiverBalanceAfter, feeReceiverBalanceBefore);
        assertGt(debtSharesBalanceAfter, debtSharesBalanceBefore);
    }

    function test_swap_maxPendingSettlementReached() public {
        for (uint256 i = 0; i < exchanger.MAX_PENDING_SETTLEMENT() - 1; i++) {
            _swap(address(xusd), address(gold), 1e4, 0);
        }

        uint256 swapFee = exchanger.getFinishSwapFee();

        vm.expectRevert(IExchanger.MaxPendingSettlementReached.selector);
        exchanger.swap{value: swapFee}(address(xusd), address(gold), 1e4, 0, address(this));
    }
}
