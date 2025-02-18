// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/// @notice Oracle adapter interface for dai oracle
interface IOracleAdapter {
    /// @notice Get the price of a token
    /// @param token The token to get the price of
    /// @return The price of the token
    /// @notice The price is scaled by precision()
    function getPrice(address token) external view returns (uint256);

    function getPriceWithTimestamp(address token) external view returns (uint256, uint256);

    /// @notice Get the precision
    /// @return The precision equals to 1e18
    function precision() external view returns (uint256);

    event FallbackOracleChanged(address oldFallbackOracle, address newFallbackOracle);

    error ZeroPrice();
}
