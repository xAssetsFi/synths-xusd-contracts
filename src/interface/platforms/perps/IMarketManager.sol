// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IMarketManager {
    /// @notice Returns the address of the market associated with the given market key.
    /// @param marketKey The unique key identifying the market.
    /// @return The address of the market contract.
    function markets(bytes32 marketKey) external view returns (address);

    /// @notice Returns the addresses of all created markets.
    /// @return An array of all market contract addresses.
    function getAllMarkets() external view returns (address[] memory);

    /// @notice Creates a new market with the specified implementation, market key, and base asset.
    /// @param implementation The address of the market implementation contract.
    /// @param marketKey The unique key for the new market.
    /// @param baseAsset The base asset identifier for the new market.
    /// @return The address of the newly created market contract.
    function createMarket(address implementation, bytes32 marketKey, bytes32 baseAsset)
        external
        returns (address);

    /// @notice Burns a specified amount of tokens from the given address.
    /// @param from The address from which tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) external;

    /// @notice Mints a specified amount of tokens to the given address.
    /// @param to The address to which tokens will be minted.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external;

    /// @notice Adds a reward amount to be distributed among debt share holders.
    /// @param amount The amount of reward to add.
    function addRewardOnDebtShares(uint256 amount) external;

    /// @notice Emitted when a new market is created.
    /// @param marketKey The unique key of the created market.
    /// @param market The address of the created market contract.
    event MarketCreated(bytes32 marketKey, address market);

    error NotMarket();
    error MarketAlreadyExists();
    error MarketNotFound();
    error UndefinedPriceForBaseAsset();
}
