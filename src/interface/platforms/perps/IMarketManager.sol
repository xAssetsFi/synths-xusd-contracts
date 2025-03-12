// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IMarketManager {
    function markets(bytes32 marketKey) external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function createMarket(address implementation, bytes32 marketKey, bytes32 baseAsset)
        external
        returns (address);

    function burn(address from, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function addRewardOnDebtShares(uint256 amount) external;

    event MarketCreated(bytes32 marketKey, address market);

    error NotMarket();
    error MarketAlreadyExists();
    error UndefinedPriceForBaseAsset();
}
