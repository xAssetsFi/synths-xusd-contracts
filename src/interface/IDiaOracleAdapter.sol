// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/// @notice Oracle adapter interface for dai oracle
interface IDiaOracleAdapter {
    event NewKey(address token, string key);
    event DiaOracleChanged(address oldDiaOracle, address newDiaOracle);

    function setKey(address token, string memory key) external;

    function setDiaOracle(address diaOracle_) external;
}
