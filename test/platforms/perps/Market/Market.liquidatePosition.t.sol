// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract LiquidatePosition is MarketSetup {
    function _afterSetup() internal override {
        super._afterSetup();

        marketGold.transferMargin(int256(amountBorrowed));

        marketGold.modifyPosition(10e18); // long position, leverage = 4
    }

    function test_ShouldLiquidatePosition() public {
        _setGoldPrice(oracleAdapter.getPrice(address(gold)) / 1000 * 760);

        address liquidator = vm.addr(0x666);
        address owner = vm.addr(0x777);

        marketGold.transferOwnership(owner);

        uint256 balanceThisBefore = xusd.balanceOf(address(this));
        uint256 balanceLiquidatorBefore = xusd.balanceOf(liquidator);
        uint256 balanceOwnerBefore = xusd.balanceOf(owner);
        uint256 balanceDebtSharesBefore = xusd.balanceOf(address(debtShares));

        vm.prank(liquidator);
        marketGold.liquidatePosition(address(this));

        uint256 balanceThisAfter = xusd.balanceOf(address(this));
        uint256 balanceLiquidatorAfter = xusd.balanceOf(liquidator);
        uint256 balanceOwnerAfter = xusd.balanceOf(owner);
        uint256 balanceDebtSharesAfter = xusd.balanceOf(address(debtShares));

        assertEq(balanceThisAfter, balanceThisBefore);
        assertGt(balanceLiquidatorAfter, balanceLiquidatorBefore);
        assertGt(balanceOwnerAfter, balanceOwnerBefore);
        assertGt(balanceDebtSharesAfter, balanceDebtSharesBefore);

        IMarket.PerpPosition memory position = marketGold.getPerpPosition(address(this));
        assertEq(position.size, 0);
        assertEq(position.margin, 0);
    }
}
