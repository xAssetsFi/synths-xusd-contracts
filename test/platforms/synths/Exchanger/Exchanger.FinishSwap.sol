// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Exchanger.Setup.sol";

contract FinishSwap is ExchangerSetup {
    function testFuzz_withoutPriceUpdate(uint256 amountIn) public {
        vm.assume(amountIn > fuzzingDust);
        vm.assume(amountIn <= amountBorrowed);

        _swap(address(xusd), address(gold), amountIn);

        IExchanger.PendingSwap memory pendingSwap =
            exchanger.getPendingSwap(address(this), address(gold));

        assertEq(pendingSwap.swaps.length, 1);
        assertEq(pendingSwap.lastUpdate, block.timestamp);

        _finishSwap(address(this), address(gold));

        pendingSwap = exchanger.getPendingSwap(address(this), address(gold));

        assertEq(pendingSwap.swaps.length, 0);
        assertEq(pendingSwap.lastUpdate, 0);
    }

    function testFuzz_withPriceUpdate(uint256 amountIn) public {
        vm.assume(amountIn > fuzzingDust);
        vm.assume(amountIn <= amountBorrowed);

        _swap(address(xusd), address(gold), amountIn);

        uint256 previewedAmountOut = exchanger.previewSwap(address(gold), address(xusd), amountIn);

        uint256 goldPrice = oracleAdapter.getPrice(address(gold));
        diaOracle.setValue("XAU/USD", uint128((goldPrice / 100) * 101));

        _finishSwap(address(this), address(gold));
        uint256 goldAfterSettle = gold.balanceOf(address(this));

        assertLe(goldAfterSettle, previewedAmountOut);
    }

    function testFuzz_multipleSwaps(uint256 amountIn) public {
        vm.assume(amountIn > fuzzingDust);
        vm.assume(amountIn <= amountBorrowed / 2);

        _swap(address(xusd), address(gold), amountIn);

        _swap(address(xusd), address(gold), amountIn);

        IExchanger.PendingSwap memory pendingSwap =
            exchanger.getPendingSwap(address(this), address(gold));

        assertEq(pendingSwap.swaps.length, 2);
        assertEq(pendingSwap.swaps[0].nonce, 0);
        assertEq(pendingSwap.swaps[1].nonce, 1);

        _finishSwap(address(this), address(gold));

        pendingSwap = exchanger.getPendingSwap(address(this), address(gold));
        assertEq(pendingSwap.swaps.length, 0);
    }
}
