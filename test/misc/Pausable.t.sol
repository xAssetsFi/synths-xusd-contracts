// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

import {Errors} from "src/common/_Errors.sol";

contract PausableTest is Setup {
    address a = makeAddr("a");

    function _afterSetup() internal override {
        super._afterSetup();
        provider.pause();
    }

    function test_pause() public view {
        assertTrue(provider.isPaused());
    }

    function test_unpause() public {
        provider.unpause();
        assertFalse(provider.isPaused());
    }

    /* ======== POOL ======== */

    function test_supply_revertIfPaused() public {
        _expectRevert();
        pool.supply(a, 0);
    }

    function test_withdraw_revertIfPaused() public {
        _expectRevert();
        pool.withdraw(a, 0, a);
    }

    function test_borrow_revertIfPaused() public {
        _expectRevert();
        pool.borrow(0, a);
    }

    function test_repay_revertIfPaused() public {
        _expectRevert();
        pool.repay(0);
    }

    function test_liquidate_revertIfPaused() public {
        _expectRevert();
        pool.liquidate(a, a, 0, a);
    }

    function test_supplyETH_revertIfPaused() public {
        _expectRevert();
        pool.supplyETH();
    }

    function test_withdrawETH_revertIfPaused() public {
        _expectRevert();
        pool.withdrawETH(0, a);
    }

    function test_supplyAndBorrow_revertIfPaused() public {
        _expectRevert();
        pool.supplyAndBorrow(a, 0, 0, a);
    }

    /* ======== EXCHANGER ======== */

    function test_swap_revertIfPaused() public {
        _expectRevert();
        exchanger.swap(a, a, 0, 0, a);
    }

    function test_settle_revertIfPaused() public {
        _expectRevert();
        exchanger.finishSwap(a, a, a);
    }

    /* ======== INTERNAL ======== */

    function _expectRevert() internal {
        vm.expectRevert(abi.encodeWithSelector(Errors.OnPause.selector));
    }
}
