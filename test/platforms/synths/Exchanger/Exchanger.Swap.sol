// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Exchanger.Setup.sol";

contract ExchangerSwapTest is ExchangerSetup {
    function testFuzz_swap(uint256 amountIn) public {
        vm.assume(amountIn > fuzzingDust);
        vm.assume(amountIn <= amountBorrowed);

        _swap(address(xusd), address(gold), amountIn);
    }

    function testFuzz_chargingFee_synthInEqXUSD(uint256 amountIn) public {
        vm.assume(amountIn > 1e4);
        vm.assume(amountIn <= amountBorrowed);

        uint256 feeReceiverBalanceBefore = xusd.balanceOf(feeReceiver);
        uint256 debtSharesBalanceBefore = xusd.balanceOf(address(debtShares));

        _swap(address(xusd), address(gold), amountIn);

        uint256 feeReceiverBalanceAfter = xusd.balanceOf(feeReceiver);
        uint256 debtSharesBalanceAfter = xusd.balanceOf(address(debtShares));

        assertGt(feeReceiverBalanceAfter, feeReceiverBalanceBefore);
        assertGt(debtSharesBalanceAfter, debtSharesBalanceBefore);
    }

    function testFuzz_chargingFee_synthInNotEqXUSD(uint256 amountIn) public {
        vm.assume(amountIn > 1e4);
        vm.assume(amountIn <= 1e50);

        deal(address(gold), address(this), amountIn);

        uint256 feeReceiverBalanceBefore = xusd.balanceOf(feeReceiver);
        uint256 debtSharesBalanceBefore = xusd.balanceOf(address(debtShares));

        _swap(address(gold), address(tesla), amountIn);

        uint256 feeReceiverBalanceAfter = xusd.balanceOf(feeReceiver);
        uint256 debtSharesBalanceAfter = xusd.balanceOf(address(debtShares));

        assertGt(feeReceiverBalanceAfter, feeReceiverBalanceBefore);
        assertGt(debtSharesBalanceAfter, debtSharesBalanceBefore);
    }
}
