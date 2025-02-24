// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/// @notice Platform is a contract that can mint and burn xusd (e.g. exchanger)
interface IPlatform {
    /// @notice Get the total market cap of the platform
    /// @return totalFunds The total funds of the platform
    function totalFunds() external view returns (uint256);
}
