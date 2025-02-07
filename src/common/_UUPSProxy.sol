// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ProviderKeeper} from "src/common/_ProviderKeeper.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

abstract contract UUPSProxy is ProviderKeeper, OwnableUpgradeable, UUPSUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function __UUPSProxy_init(address _owner, address _provider) internal onlyInitializing {
        __Ownable_init(_owner);
        __ProviderKeeper_init(_provider);
    }

    function initialize(address _owner, address _provider) public virtual initializer {
        __UUPSProxy_init(_owner, _provider);
        _afterInitialize();
    }

    function _afterInitialize() internal virtual;

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function implementation() public view returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
