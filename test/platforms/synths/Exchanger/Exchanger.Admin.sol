// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Exchanger.Setup.sol";

contract ExchangerAdminTest is ExchangerSetup {
    uint256 newUint = 52;
    address newAddress = address(0x52);

    function test_setSwapFee() public {
        vm.expectEmit(true, true, true, true);
        emit IExchanger.SwapFeeChanged(newUint);
        exchanger.setSwapFee(newUint);
        assertEq(exchanger.swapFee(), newUint);
    }

    function test_setFeeReceiver() public {
        vm.expectEmit(true, true, true, true);
        emit IExchanger.FeeReceiverChanged(newAddress);
        exchanger.setFeeReceiver(newAddress);
        assertEq(exchanger.feeReceiver(), newAddress);
    }

    function test_setSettlementDelay() public {
        vm.expectEmit(true, true, true, true);
        emit IExchanger.FinishSwapDelayChanged(newUint);
        exchanger.setFinishSwapDelay(newUint);
        assertEq(exchanger.finishSwapDelay(), newUint);
    }

    function test_setBurntAtSwap() public {
        vm.expectEmit(true, true, true, true);
        emit IExchanger.BurntAtSwapChanged(newUint);
        exchanger.setBurntAtSwap(newUint);
        assertEq(exchanger.burntAtSwap(), newUint);
    }
}
