// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Base} from "src/common/_Base.sol";
import {IProvider} from "src/interface/IProvider.sol";

abstract contract ProviderKeeper is Base {
    IProvider private _provider;

    function __ProviderKeeper_init(address newProvider)
        internal
        noZeroAddress(newProvider)
        onlyInitializing
        validInterface(newProvider, type(IProvider).interfaceId)
    {
        _provider = IProvider(newProvider);
    }

    function provider() internal view noZeroAddress(address(_provider)) returns (IProvider) {
        return _provider;
    }

    /* ======== Modifiers ======== */

    modifier noPaused() {
        if (provider().isPaused()) revert OnPause();
        _;
    }
}
