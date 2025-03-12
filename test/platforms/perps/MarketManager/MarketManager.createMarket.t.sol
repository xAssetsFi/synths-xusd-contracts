// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_MarketManager.Setup.t.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CreateMarket is MarketManagerSetup {
    function test_ShouldRevertIfNotOwner() public {
        bytes memory onlyOwnerRevertData =
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketManager.createMarket(address(_marketImplementation), "sXAU1", "XAU");
    }

    function test_ShouldCreateMarket() public {
        address market = marketManager.createMarket(address(_marketImplementation), "sXAU1", "XAU");

        assertEq(marketManager.markets("sXAU1"), market);
    }

    function test_ShouldRevertIfMarketAlreadyExists() public {
        marketManager.createMarket(address(_marketImplementation), "sXAU1", "XAU");

        vm.expectRevert(abi.encodeWithSelector(IMarketManager.MarketAlreadyExists.selector));
        marketManager.createMarket(address(_marketImplementation), "sXAU1", "XAU");
    }
}
