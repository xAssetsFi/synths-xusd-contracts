// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDIAOracleV2} from "../interface/external/IDIAOracleV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DiaOracle is IDIAOracleV2, Ownable {
    mapping(string key => uint256 price) internal prices;
    uint256 internal gasPrice;

    constructor(string[] memory _keys, uint256[] memory _prices) Ownable(msg.sender) {
        _setValues(_keys, _prices);
    }

    function getValue(string memory key) external view returns (uint128 price, uint128 timestamp) {
        return (uint128(prices[key]), uint128(block.timestamp));
    }

    function setValue(string memory key, uint256 price) external onlyOwner {
        prices[key] = price;
    }

    function setValues(string[] memory _keys, uint256[] memory _prices) external onlyOwner {
        _setValues(_keys, _prices);
    }

    function _setValues(string[] memory _keys, uint256[] memory _prices) internal {
        require(_keys.length == _prices.length, "FallbackOracle: Invalid input");

        for (uint256 i = 0; i < _keys.length; i++) {
            prices[_keys[i]] = _prices[i];
        }
    }
}
