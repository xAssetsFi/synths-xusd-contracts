// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_MarketManager.Setup.t.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RemoveMarket is MarketManagerSetup {
    address market;

    function _afterSetup() internal override {
        super._afterSetup();

        marketKey = "sXAU1";

        market = marketManager.createMarket(address(_marketImplementation), marketKey, "XAU");
    }

    function test_ShouldRevertIfNotOwner() public {
        bytes memory onlyOwnerRevertData =
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketManager.removeMarket(marketKey);
    }

    function test_ShouldRemoveMarket() public {
        marketManager.removeMarket(marketKey);

        assertEq(marketManager.markets(marketKey), address(0));
    }

    // function test_ShouldRevertIfMarketDoesNotExist() public {
    //     vm.expectRevert(abi.encodeWithSelector(IMarketManager.MarketDoesNotExist.selector));
    //     marketManager.removeMarket(marketKey);
    // }
}
