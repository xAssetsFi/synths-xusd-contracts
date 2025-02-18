// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Exchanger.Setup.sol";

contract ExchangerAdminTest is ExchangerSetup {
    uint256 newUint = 52;
    address newAddress = address(0x52);

    function test_setSwapFee() public {
        vm.expectEmit();
        emit IExchanger.SwapFeeChanged(newUint);
        exchanger.setSwapFee(newUint);
        assertEq(exchanger.swapFee(), newUint);
    }

    function test_setFeeReceiver() public {
        vm.expectEmit();
        emit IExchanger.FeeReceiverChanged(newAddress);
        exchanger.setFeeReceiver(newAddress);
        assertEq(exchanger.feeReceiver(), newAddress);
    }

    function test_setSettlementDelay() public {
        vm.expectEmit();
        emit IExchanger.FinishSwapDelayChanged(newUint);
        exchanger.setFinishSwapDelay(newUint);
        assertEq(exchanger.finishSwapDelay(), newUint);
    }

    function test_setBurntAtSwap() public {
        vm.expectEmit();
        emit IExchanger.BurntAtSwapChanged(newUint);
        exchanger.setBurntAtSwap(newUint);
        assertEq(exchanger.burntAtSwap(), newUint);
    }

    function test_addNewSynth() public {
        vm.expectEmit(false, false, false, false);
        emit IExchanger.SynthAdded(address(0));
        address synth = exchanger.createSynth(address(new Synth()), address(this), "Test", "TST");
        assertEq(exchanger.isSynth(synth), true);
    }

    function test_addNewSynth_revertIfSynthAlreadyExists() public {
        vm.expectRevert(IExchanger.SynthAlreadyExists.selector);
        exchanger.addNewSynth(address(xusd));
    }

    function test_removeSynth() public {
        vm.expectEmit();
        emit IExchanger.SynthRemoved(address(xusd));
        exchanger.removeSynth(address(xusd));
        assertEq(exchanger.isSynth(address(xusd)), false);
    }
}
