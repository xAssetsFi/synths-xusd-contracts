// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract ModifyPositionAndTransferMargin is MarketSetup {
    function test_ShouldModifyPositionAndTransferMargin() public {
        int256 targetPositionSize = 1e18 / 4; // leverage = 1

        marketGold.transferOwnership(address(0xdead));

        marketGold.transferMarginAndModifyPosition(int256(amountBorrowed), targetPositionSize);

        marketGold.modifyPositionAndTransferMargin(-targetPositionSize, -type(int256).max);

        assertEq(marketGold.getPerpPosition(address(this)).margin, 0);
        assertEq(marketGold.getPerpPosition(address(this)).size, 0);

        assertEq(xusd.balanceOf(address(this)), 4998249497811875000000);
    }
}
