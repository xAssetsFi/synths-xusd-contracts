// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IPlatform} from "src/interface/platforms/IPlatform.sol";
import {IMarket} from "src/interface/platforms/perps/IMarket.sol";
import {IMarketManager} from "src/interface/platforms/perps/IMarketManager.sol";

import {ProviderKeeperUpgradeable} from "src/common/_ProviderKeeperUpgradeable.sol";

import {ArrayLib} from "src/lib/ArrayLib.sol";

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

        if (provider().oracle().getPrice(address(uint160(uint256(baseAsset)))) == 0) {
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
        _markets.remove(markets[marketKey]); // TODO: check if remove succeeds
        delete markets[marketKey];
    }

    function mint(address to, uint256 amount) external onlyMarket {
        provider().xusd().mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyMarket {
        provider().xusd().burn(from, amount);
    }

    function addRewardOnDebtShares(uint256 amount) external onlyMarket {
        provider().xusd().mint(address(this), amount);
        provider().xusd().approve(address(provider().pool().debtShares()), amount);
        provider().pool().debtShares().addReward(address(provider().xusd()), amount);
    }

    function totalFunds() external view returns (uint256 tf) {
        for (uint256 i; i < _markets.length; i++) {
            IMarket market = IMarket(_markets[i]);

            tf += market.marketSize() * market.assetPrice();
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
