// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IPlatform} from "src/interface/platforms/IPlatform.sol";
import {IMarket} from "src/interface/platforms/perps/IMarket.sol";
import {IMarketManager} from "src/interface/platforms/perps/IMarketManager.sol";
import {IProvider} from "src/interface/IProvider.sol";
import {ProviderKeeperUpgradeable} from "src/common/_ProviderKeeperUpgradeable.sol";

import {ArrayLib} from "src/lib/ArrayLib.sol";
import {MarketLib} from "src/lib/MarketLib.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract MarketManager is ProviderKeeperUpgradeable, IMarketManager, IPlatform {
    using Clones for address;
    using ArrayLib for address[];

    address[] private _markets;

    mapping(bytes32 => address) public markets;

    function initialize(address _provider) external initializer {
        __ProviderKeeper_init(_provider);

        _registerInterface(type(IPlatform).interfaceId);
        _registerInterface(type(IMarketManager).interfaceId);
    }

    function createMarket(address implementation, bytes32 marketKey, bytes32 baseAsset)
        external
        onlyOwner
        returns (address)
    {
        if (markets[marketKey] != address(0)) revert MarketAlreadyExists();

        if (provider().oracle().getPrice(MarketLib.getAddress(baseAsset)) == 0) {
            revert UndefinedPriceForBaseAsset();
        }

        address market = implementation.clone();
        IMarket(market).initialize(address(provider()), marketKey, baseAsset);
        markets[marketKey] = market;
        _markets.push(market);
        emit MarketCreated(marketKey, market);
        return market;
    }

    function removeMarket(bytes32 marketKey) external onlyOwner {
        bool removed = _markets.remove(markets[marketKey]);
        if (!removed) revert MarketNotFound();
        delete markets[marketKey];
    }

    function mint(address to, uint256 amount) external onlyMarket {
        provider().xusd().mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyMarket {
        provider().xusd().burn(from, amount);
    }

    function addRewardOnDebtShares(uint256 amount) external onlyMarket {
        IProvider _provider = provider();

        _provider.xusd().mint(address(this), amount);
        _provider.xusd().approve(address(_provider.pool().debtShares()), amount);
        _provider.pool().debtShares().addReward(address(_provider.xusd()), amount);
    }

    function totalFunds() external view returns (uint256 tf) {
        for (uint256 i; i < _markets.length; i++) {
            IMarket market = IMarket(_markets[i]);

            tf += market.marketDebt(market.assetPrice());
        }
    }

    function getAllMarkets() external view returns (address[] memory) {
        return _markets;
    }

    modifier onlyMarket() {
        if (markets[IMarket(msg.sender).marketKey()] != msg.sender) revert NotMarket();
        _;
    }
}
