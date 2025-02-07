// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {UUPSProxy} from "src/common/_UUPSProxy.sol";

import {IDiaOracleAdapter} from "src/interface/IDiaOracleAdapter.sol";
import {IDIAOracleV2} from "src/interface/external/IDIAOracleV2.sol";
import {IOracleAdapter} from "src/interface/IOracleAdapter.sol";

contract DiaOracleAdapter is IDiaOracleAdapter, IOracleAdapter, UUPSProxy {
    IDIAOracleV2 public diaOracle;

    IOracleAdapter public fallbackOracle;

    mapping(address token => string key) public keys;

    function initialize(address _owner, address _provider, address _diaOracle) public initializer {
        __UUPSProxy_init(_owner, _provider);
        diaOracle = IDIAOracleV2(_diaOracle);
        _afterInitialize();
    }

    /* ======== External Functions ======== */

    function getPrice(address token) external view returns (uint256) {
        if (token == address(provider().xusd())) return precision(); // xusd is always 1

        string memory key = keys[token];
        (uint128 price,) = diaOracle.getValue(key);

        return _validatePrice(uint256(price), token);
    }

    function precision() public pure returns (uint256) {
        return 1e8;
    }

    function _validatePrice(uint256 price, address token) internal view returns (uint256) {
        if (price == 0) price = fallbackOracle.getPrice(token);

        if (price == 0) revert ZeroPrice();

        return price;
    }

    /* ======== Admin ======== */

    function setKey(address token, string memory key) external onlyOwner {
        keys[token] = key;
        emit NewKey(token, key);
    }

    function setDiaOracle(address diaOracle_) external onlyOwner {
        emit DiaOracleChanged(address(diaOracle), diaOracle_);
        diaOracle = IDIAOracleV2(diaOracle_);
    }

    function setFallbackOracle(address fallbackOracle_)
        external
        onlyOwner
        validInterface(fallbackOracle_, type(IOracleAdapter).interfaceId)
    {
        emit FallbackOracleChanged(address(fallbackOracle), fallbackOracle_);
        fallbackOracle = IOracleAdapter(fallbackOracle_);
    }

    function _afterInitialize() internal override {
        _registerInterface(type(IOracleAdapter).interfaceId);
    }
}
