// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_MarketManager.Setup.t.sol";

contract Mint is MarketManagerSetup {
    function test_ShouldRevertIfNotMarket() public {
        vm.expectRevert(IMarketManager.NotMarket.selector);
        marketManager.mint(user, 100);
    }

    function test_ShouldMint() public {
        address market = marketManager.createMarket(address(_marketImplementation), "sXAU1", "XAU");

        vm.prank(market);
        marketManager.mint(user, 100);

        assertEq(xusd.balanceOf(user), 100);
    }
}
