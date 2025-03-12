// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract ClosePosition is MarketSetup {
    function test_ShouldClosePosition() public {
        marketGold.transferMargin(int256(amountBorrowed));
        marketGold.modifyPosition(1e18);

        marketGold.closePosition(1);
        int128 sizeAfter = marketGold.getPerpPosition(address(this)).size;

        assertEq(sizeAfter, 0);
    }
}
