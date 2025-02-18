// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IProvider} from "src/interface/IProvider.sol";

import {Base} from "src/common/_Base.sol";

import {PausableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {ISynth} from "src/interface/platforms/synths/ISynth.sol";
import {IPool} from "src/interface/IPool.sol";
import {IExchanger} from "src/interface/platforms/synths/IExchanger.sol";
import {IOracleAdapter} from "src/interface/IOracleAdapter.sol";
import {IPlatform} from "src/interface/platforms/IPlatform.sol";

contract Provider is IProvider, Base, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    address private _xusd;
    address private _pool;
    address private _oracle;

    // platforms
    address private _exchanger;

    mapping(address => bool) public isPlatform;

    IPlatform[] private _platforms;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        __Pausable_init();

        _registerInterface(type(IProvider).interfaceId);
    }

    /* ======== Setters ======== */

    function setXUSD(address newXUSD)
        external
        onlyOwner
        noZeroAddress(newXUSD)
        validInterface(newXUSD, type(ISynth).interfaceId)
    {
        emit XUSDChanged(_xusd, newXUSD);
        _xusd = newXUSD;
    }

    function setExchanger(address newExchanger)
        external
        onlyOwner
        noZeroAddress(newExchanger)
        validInterface(newExchanger, type(IExchanger).interfaceId)
    {
        emit ExchangerChanged(_exchanger, newExchanger);
        _addPlatform(newExchanger);
        _exchanger = newExchanger;
    }

    function setPool(address newPool)
        external
        onlyOwner
        noZeroAddress(newPool)
        validInterface(newPool, type(IPool).interfaceId)
    {
        emit PoolChanged(_pool, newPool);
        _pool = newPool;
    }

    function setOracle(address newOracle)
        external
        onlyOwner
        noZeroAddress(newOracle)
        validInterface(newOracle, type(IOracleAdapter).interfaceId)
    {
        emit OracleChanged(_oracle, newOracle);
        _oracle = newOracle;
    }

    /* ======== Getters ======== */

    function xusd() external view noZeroAddress(_xusd) returns (ISynth) {
        return ISynth(_xusd);
    }

    function exchanger() external view noZeroAddress(_exchanger) returns (IExchanger) {
        return IExchanger(_exchanger);
    }

    function pool() external view noZeroAddress(_pool) returns (IPool) {
        return IPool(_pool);
    }

    function oracle() external view noZeroAddress(_oracle) returns (IOracleAdapter) {
        return IOracleAdapter(_oracle);
    }

    function platforms() external view returns (IPlatform[] memory) {
        return _platforms;
    }

    function isPaused() public view returns (bool) {
        return paused();
    }

    function implementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    /* ======== Admin ======== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function removePlatform(address platform) external onlyOwner {
        _removePlatform(platform);
    }

    /* ======== Internal ======== */

    function _removePlatform(address platform) internal {
        if (!isPlatform[platform]) revert PlatformNotFound();

        isPlatform[platform] = false;

        for (uint256 i = 0; i < _platforms.length; i++) {
            if (address(_platforms[i]) == platform) {
                _platforms[i] = _platforms[_platforms.length - 1];
                _platforms.pop();
                break;
            }
        }

        emit PlatformRemoved(platform);
    }

    function _addPlatform(address platform)
        internal
        validInterface(platform, type(IPlatform).interfaceId)
    {
        if (isPlatform[platform]) revert PlatformAlreadyAdded();

        isPlatform[platform] = true;
        _platforms.push(IPlatform(platform));

        emit NewPlatform(platform);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
