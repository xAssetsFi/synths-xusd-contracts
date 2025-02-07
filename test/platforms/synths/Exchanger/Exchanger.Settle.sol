// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Exchanger.Setup.sol";

contract ExchangerSettleTest is ExchangerSetup {
    function testFuzz_settle_withoutPriceUpdate(uint256 amountIn) public {
        vm.assume(amountIn > fuzzingDust);
        vm.assume(amountIn <= amountBorrowed);

        _swap(address(xusd), address(gold), amountIn);

        IExchanger.Settlement memory settlement =
            exchanger.getSettlement(address(this), address(gold));

        assertEq(settlement.swaps.length, 1);
        assertEq(settlement.lastUpdate, block.timestamp);

        _settle(address(this), address(gold));

        settlement = exchanger.getSettlement(address(this), address(gold));

        assertEq(settlement.swaps.length, 0);
        assertEq(settlement.lastUpdate, 0);
    }

    function testFuzz_settle_withPriceUpdate(uint256 amountIn) public {
        vm.assume(amountIn > fuzzingDust);
        vm.assume(amountIn <= amountBorrowed);

        _swap(address(xusd), address(gold), amountIn);

        uint256 goldAfterSwap = gold.balanceOf(address(this));

        uint256 goldPrice = oracleAdapter.getPrice(address(gold));
        goldPrice = (goldPrice / 100) * 101;
        diaOracle.setValue("XAU/USD", uint128(goldPrice), uint128(block.timestamp));

        _settle(address(this), address(gold));

        uint256 goldAfterSettle = gold.balanceOf(address(this));

        assertLe(goldAfterSettle, goldAfterSwap);
    }

    function testFuzz_settle_multipleSwaps(uint256 amountIn) public {
        vm.assume(amountIn > fuzzingDust);
        vm.assume(amountIn <= amountBorrowed / 2);

        _swap(address(xusd), address(gold), amountIn);
        _swap(address(xusd), address(gold), amountIn);

        IExchanger.Settlement memory settlement =
            exchanger.getSettlement(address(this), address(gold));
        assertEq(settlement.swaps.length, 2);
        assertEq(settlement.swaps[0].nonce, 0);
        assertEq(settlement.swaps[1].nonce, 1);

        _settle(address(this), address(gold));

        settlement = exchanger.getSettlement(address(this), address(gold));
        assertEq(settlement.swaps.length, 0);
    }

    function _settle(address user, address synth) internal {
        skip(exchanger.settlementDelay());
        uint256 balanceBeforeSettle = address(this).balance;
        exchanger.settle(user, synth, user);
        assertGe(address(this).balance, balanceBeforeSettle);
    }
}
