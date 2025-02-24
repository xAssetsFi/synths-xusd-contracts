// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IOracleAdapter} from "src/interface/IOracleAdapter.sol";

/// @notice Oracle adapter interface for dai oracle
interface IDiaOracleAdapter is IOracleAdapter {
    event NewKey(address token, string key);
    event DiaOracleChanged(address oldDiaOracle, address newDiaOracle);

    function setKey(address token, string memory key) external;

    function setDiaOracle(address diaOracle_) external;

    error PriceStale(uint256 currentTimestamp, uint256 lastUpdatedTimestamp);
}
