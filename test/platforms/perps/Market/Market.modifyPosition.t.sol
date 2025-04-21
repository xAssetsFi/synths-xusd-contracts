// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract ModifyPosition is MarketSetup {
    function _afterSetup() internal override {
        super._afterSetup();

        marketGold.transferMargin(int256(amountBorrowed));
    }

    function testFuzz_ShouldModifyPositionSize(int256 targetPositionSize) public {
        vm.assume(targetPositionSize != 0);
        vm.assume(targetPositionSize != type(int256).min);

        vm.assume(
            SignedSafeMath.abs(targetPositionSize)
                < (
                    marketGold.getPerpPosition(address(this)).margin * marketGold.maxLeverage()
                        / marketGold.assetPrice()
                )
        );

        address feeReceiver = address(0x777);
        marketGold.setFeeReceiver(feeReceiver);

        uint256 balanceFeeReceiverBefore = xusd.balanceOf(feeReceiver);
        uint256 balanceDebtSharesBefore = xusd.balanceOf(address(debtShares));

        marketGold.modifyPosition(
            targetPositionSize, marketGold.fillPrice(targetPositionSize, marketGold.assetPrice())
        );

        uint256 balanceFeeReceiverAfter = xusd.balanceOf(feeReceiver);
        uint256 balanceDebtSharesAfter = xusd.balanceOf(address(debtShares));

        assertGt(balanceFeeReceiverAfter, balanceFeeReceiverBefore);
        assertGt(balanceDebtSharesAfter, balanceDebtSharesBefore);

        assertEq(marketGold.getPerpPosition(address(this)).size, targetPositionSize);
    }

    function testFuzz_ShouldCompleteProfitableLongTrade(uint256 priceMultiplier) public {
        vm.assume(priceMultiplier > 1000 && priceMultiplier < 100000);

        int256 targetPositionSize = 1e18 / 4; // leverage = 1

        uint256 marginBefore = marketGold.getPerpPosition(address(this)).margin;
        marketGold.modifyPosition(targetPositionSize);
        _setGoldPrice(oracleAdapter.getPrice(address(gold)) / 10000 * (10000 + priceMultiplier));
        marketGold.modifyPosition(-targetPositionSize);
        uint256 marginAfter = marketGold.getPerpPosition(address(this)).margin;

        assertGt(marginAfter, marginBefore);
    }

    function testFuzz_ShouldCompleteProfitableShortTrade(uint256 priceMultiplier) public {
        vm.assume(priceMultiplier > 1000 && priceMultiplier < 10000);

        int256 targetPositionSize = -1e18 / 4; // leverage = 1

        uint256 marginBefore = marketGold.getPerpPosition(address(this)).margin;
        marketGold.modifyPosition(targetPositionSize);
        _setGoldPrice(oracleAdapter.getPrice(address(gold)) / 10000 * (10000 - priceMultiplier));
        marketGold.modifyPosition(-targetPositionSize);
        uint256 marginAfter = marketGold.getPerpPosition(address(this)).margin;

        assertGt(marginAfter, marginBefore);
    }

    function testFuzz_ShouldCompleteUnprofitableLongTrade(uint256 priceMultiplier) public {
        vm.assume(priceMultiplier > 1000 && priceMultiplier < 10000);

        int256 targetPositionSize = 1e18 / 4; // leverage = 1

        uint256 marginBefore = marketGold.getPerpPosition(address(this)).margin;
        marketGold.modifyPosition(targetPositionSize);
        _setGoldPrice(oracleAdapter.getPrice(address(gold)) / 10000 * (10000 - priceMultiplier));
        marketGold.modifyPosition(-targetPositionSize);
        uint256 marginAfter = marketGold.getPerpPosition(address(this)).margin;

        assertLt(marginAfter, marginBefore);
    }

    function testFuzz_ShouldCompleteUnprofitableShortTrade(uint256 priceMultiplier) public {
        vm.assume(priceMultiplier > 1000 && priceMultiplier < 10000);

        int256 targetPositionSize = -1e18 / 4; // leverage = 1

        uint256 marginBefore = marketGold.getPerpPosition(address(this)).margin;
        marketGold.modifyPosition(targetPositionSize);
        _setGoldPrice(oracleAdapter.getPrice(address(gold)) / 10000 * (10000 + priceMultiplier));
        marketGold.modifyPosition(-targetPositionSize);
        uint256 marginAfter = marketGold.getPerpPosition(address(this)).margin;

        assertLt(marginAfter, marginBefore);
    }
}
