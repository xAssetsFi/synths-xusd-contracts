// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Base} from "src/common/_Base.sol";
import {IProvider} from "src/interface/IProvider.sol";

abstract contract ProviderKeeperUpgradeable is Base {
    /// @custom:storage-location erc7201:xAssetsFinance.storage.ProviderKeeper
    struct ProviderStorage {
        IProvider _provider;
    }

    // keccak256(abi.encode(uint256(keccak256("xAssetsFinance.storage.ProviderKeeper")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ProviderKeeperStorageLocation =
        0x5fe73703b28fc709e38b4101c1487f6df3a5d272e7e4c3dbfc59a2243abca900;

    function _getProviderStorage() private pure returns (ProviderStorage storage $) {
        assembly {
            $.slot := ProviderKeeperStorageLocation
        }
    }

    function __ProviderKeeper_init(address newProvider)
        internal
        noZeroAddress(newProvider)
        onlyInitializing
        validInterface(newProvider, type(IProvider).interfaceId)
    {
        ProviderStorage storage $ = _getProviderStorage();
        $._provider = IProvider(newProvider);
    }

    function provider()
        internal
        view
        noZeroAddress(address(_getProviderStorage()._provider))
        returns (IProvider)
    {
        ProviderStorage storage $ = _getProviderStorage();
        return $._provider;
    }

    /* ======== Modifiers ======== */

    modifier noPaused() {
        if (provider().isPaused()) revert OnPause();
        _;
    }
}
