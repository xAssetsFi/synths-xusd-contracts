// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IDIAOracleV2} from "src/interface/external/IDIAOracleV2.sol";

contract DiaOracleMock is IDIAOracleV2 {
    mapping(string => uint256) public values;

    event OracleUpdate(string key, uint128 value, uint128 timestamp);

    function setValue(string memory key, uint128 value, uint128 timestamp) public {
        uint256 cValue = (((uint256)(value)) << 128) + timestamp;
        values[key] = cValue;
        emit OracleUpdate(key, value, timestamp);
    }

    function getValue(string memory key) external view returns (uint128, uint128) {
        uint256 cValue = values[key];
        uint128 timestamp = (uint128)(cValue % 2 ** 128);
        uint128 value = (uint128)(cValue >> 128);
        return (value, timestamp);
    }
}
