// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/// @notice Platform is a contract that can mint and burn xusd (e.g. exchanger)
interface IPlatform {
    /// @notice Check if a synth for a specific user is transferable
    /// @notice Synth can be transferable if all settlements is done
    /// @param token The address of the token
    /// @param user The address of the user
    /// @return isTransferable True if the synth is transferable, false otherwise
    function isTransferable(address token, address user) external view returns (bool);

    /// @notice Get the total market cap of the platform
    /// @return totalFunds The total funds of the platform
    function totalFunds() external view returns (uint256);
}
