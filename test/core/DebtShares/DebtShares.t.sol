// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_DebtShares.Setup.sol";

import {Errors} from "src/common/_Errors.sol";

contract DebtSharesTest is DebtSharesSetup {
    function test_transfer_revertsIfSenderIsNotPool() public {
        vm.expectRevert(Errors.Unauthorized.selector);
        debtShares.transfer(address(12345), 1);
    }

    function test_transfer_fromPool() public {
        deal(address(debtShares), address(pool), 1);

        vm.prank(address(pool));
        vm.expectRevert(Errors.UnAllowedAction.selector);
        debtShares.transfer(address(12345), 1);
    }

    function test_transfer_transferFromByPool() public {
        address luckyGuy = makeAddr("luckyGuy");
        address victim = makeAddr("victim");

        deal(address(debtShares), luckyGuy, 1);

        vm.prank(luckyGuy);
        debtShares.approve(address(pool), 1);

        vm.prank(address(pool));
        vm.expectRevert(Errors.UnAllowedAction.selector);
        debtShares.transferFrom(luckyGuy, victim, 1);
    }
}
