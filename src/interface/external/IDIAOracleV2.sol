// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IDIAOracleV2 {
    function getValue(string memory) external view returns (uint128 price, uint128 timestamp);
}
