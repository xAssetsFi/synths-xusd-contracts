// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract WithdrawAllMargin is MarketSetup {
    function test_ShouldWithdrawAllMargin() public {
        marketGold.transferMargin(int256(amountBorrowed));

        marketGold.withdrawAllMargin();

        uint256 marginAfter = marketGold.getPerpPosition(address(this)).margin;

        assertEq(marginAfter, 0);
    }

    function test_ShouldWithdrawAllMarginIfPositionIsOpen() public {
        marketGold.transferMargin(int256(amountBorrowed));
        marketGold.modifyPosition(1e18);

        uint256 marginBefore = marketGold.getPerpPosition(address(this)).margin;
        uint256 balanceThisBefore = xusd.balanceOf(address(this));

        marketGold.withdrawAllMargin();

        uint256 marginAfter = marketGold.getPerpPosition(address(this)).margin;
        uint256 balanceThisAfter = xusd.balanceOf(address(this));

        assertGt(balanceThisAfter, balanceThisBefore);
        assertLt(marginAfter, marginBefore);
    }
}
