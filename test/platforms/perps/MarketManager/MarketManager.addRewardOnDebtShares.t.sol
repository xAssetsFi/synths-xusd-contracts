// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_MarketManager.Setup.t.sol";

contract AddRewardOnDebtShares is MarketManagerSetup {
    function test_ShouldRevertIfNotMarket() public {
        vm.expectRevert(IMarketManager.NotMarket.selector);
        marketManager.addRewardOnDebtShares(100);
    }

    function test_ShouldAddRewardOnDebtShares() public {
        address market = marketManager.createMarket(address(_marketImplementation), "sXAU1", "XAU");

        vm.prank(market);
        marketManager.addRewardOnDebtShares(100);

        assertEq(xusd.balanceOf(address(debtShares)), 100);
    }
}
