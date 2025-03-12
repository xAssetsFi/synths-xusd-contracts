// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_MarketManager.Setup.t.sol";

contract Burn is MarketManagerSetup {
    function test_ShouldRevertIfNotMarket() public {
        vm.expectRevert(IMarketManager.NotMarket.selector);
        marketManager.burn(user, 100);
    }

    function test_ShouldBurn() public {
        address market = marketManager.createMarket(address(_marketImplementation), "sXAU1", "XAU");

        deal(address(xusd), user, 100);

        vm.prank(market);
        marketManager.burn(user, 100);

        assertEq(xusd.balanceOf(user), 0);
    }
}
