// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ProviderSetup} from "./_Provider.Setup.sol";

import {IProvider} from "src/interface/IProvider.sol";

import {IExchanger} from "src/interface/platforms/synths/IExchanger.sol";
import {ISynth} from "src/interface/platforms/synths/ISynth.sol";
import {IPool} from "src/interface/IPool.sol";
import {IOracleAdapter} from "src/interface/IOracleAdapter.sol";
import {IPlatform} from "src/interface/platforms/IPlatform.sol";
import {ERC165Registry} from "src/common/_ERC165Registry.sol";

contract ProviderAdminTest is ProviderSetup {
    address newAddress;

    function _afterSetup() internal override {
        newAddress = address(new Mock());
    }

    function test_setOracleAdapter() public {
        address oldOracle = address(provider.oracle());
        vm.expectEmit(true, true, true, true);
        emit IProvider.OracleChanged(oldOracle, newAddress);
        provider.setOracle(newAddress);
        assertEq(address(provider.oracle()), newAddress);
    }

    function test_setPool() public {
        address oldPool = address(provider.pool());
        vm.expectEmit(true, true, true, true);
        emit IProvider.PoolChanged(oldPool, newAddress);
        provider.setPool(newAddress);
        assertEq(address(provider.pool()), newAddress);
    }

    function test_setExchanger() public {
        address oldExchanger = address(provider.exchanger());
        vm.expectEmit(true, true, true, true);
        emit IProvider.ExchangerChanged(oldExchanger, newAddress);
        provider.setExchanger(newAddress);
        assertEq(address(provider.exchanger()), newAddress);
    }

    function test_setXUSD() public {
        address oldXUSD = address(provider.xusd());
        vm.expectEmit(true, true, true, true);
        emit IProvider.XUSDChanged(oldXUSD, newAddress);
        provider.setXUSD(newAddress);
        assertEq(address(provider.xusd()), newAddress);
    }

    function test_removeSynth() public {
        address[] memory synths = exchanger.synths();

        exchanger.addNewSynth(newAddress);
        assertEq(exchanger.synths().length, synths.length + 1);

        vm.expectEmit(true, true, true, true);
        emit IExchanger.SynthRemoved(newAddress);
        exchanger.removeSynth(newAddress);

        assertEq(exchanger.synths().length, synths.length);
        assertFalse(exchanger.isSynth(newAddress));
    }
}

contract Mock is ERC165Registry {
    constructor() {
        _registerInterface(type(IProvider).interfaceId);
        _registerInterface(type(IOracleAdapter).interfaceId);
        _registerInterface(type(IPool).interfaceId);
        _registerInterface(type(IPlatform).interfaceId);
        _registerInterface(type(IExchanger).interfaceId);
        _registerInterface(type(ISynth).interfaceId);
    }
}
