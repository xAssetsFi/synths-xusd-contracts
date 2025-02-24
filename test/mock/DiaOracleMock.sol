// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IDIAOracleV2} from "src/interface/external/IDIAOracleV2.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DiaOracleMock is IDIAOracleV2, Ownable {
    mapping(string => uint256) public values;

    event OracleUpdate(string key, uint128 value, uint128 timestamp);

    constructor() Ownable(msg.sender) {}

    function getValue(string memory key) external view returns (uint128 price, uint128 timestamp) {
        uint256 cValue = values[key];
        timestamp = (uint128)(cValue % 2 ** 128);
        price = (uint128)(cValue >> 128);
    }

    function setValue(string memory key, uint128 price) public onlyOwner {
        uint128 timestamp = uint128(block.timestamp);

        uint256 cValue = (((uint256)(price)) << 128) + timestamp;
        values[key] = cValue;
        emit OracleUpdate(key, price, timestamp);
    }

    function setValues(string[] memory _keys, uint128[] memory _prices) external onlyOwner {
        require(_keys.length == _prices.length, "FallbackOracle: Invalid input");

        for (uint256 i = 0; i < _keys.length; i++) {
            setValue(_keys[i], _prices[i]);
        }
    }
}
