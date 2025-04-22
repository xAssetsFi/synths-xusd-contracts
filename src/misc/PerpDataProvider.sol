// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Market} from "src/platforms/perps/Market.sol";
import {IPerpDataProvider} from "src/interface/misc/IPerpDataProvider.sol";

import {ProviderKeeperUpgradeable} from "src/common/_ProviderKeeperUpgradeable.sol";

contract PerpDataProvider is IPerpDataProvider, ProviderKeeperUpgradeable {
    function initialize(address provider) public initializer {
        __ProviderKeeper_init(provider);

        _registerInterface(type(IPerpDataProvider).interfaceId);
    }

    function aggregatePerpData() external view returns (AggregatedPerpData memory) {
        return _aggregatePerpData(address(0));
    }

    function aggregatePerpData(address account) external view returns (AggregatedPerpData memory) {
        return _aggregatePerpData(account);
    }

    function _aggregatePerpData(address account)
        internal
        view
        returns (AggregatedPerpData memory data)
    {
        address[] memory markets = provider().marketManager().getAllMarkets();

        data = AggregatedPerpData({marketData: new MarketData[](markets.length)});

        for (uint256 i; i < markets.length; i++) {
            Market market = Market(markets[i]);
            (uint256 long, uint256 short) = market.marketSizes();

            PositionData memory pd;

            uint256 price = market.assetPrice();

            pd.position = market.getPerpPosition(account);

            if (account != address(0)) {
                pd.notionalValue = market.notionalValue(pd.position.size, price);
                pd.profitLoss = market.profitLoss(pd.position, price);
                pd.accruedFunding = market.accruedFunding(pd.position, price);
                pd.remainingMargin = market.remainingMargin(pd.position, price);
                pd.accessibleMargin = market.accessibleMargin(pd.position, price);
                pd.liquidationPrice = market.liquidationPrice(pd.position);
                pd.leverage = market.currentLeverage(pd.position.size, price, pd.remainingMargin);
                pd.canLiquidate = market.canLiquidate(pd.position, price);
            }

            data.marketData[i] = MarketData({
                market: address(market),
                asset: market.baseAsset(),
                key: market.marketKey(),
                minInitialMargin: market.minInitialMargin(),
                liquidationFeeRatio: market.liquidationFeeRatio(),
                minLiquidatorFee: market.minLiquidatorFee(),
                maxLiquidatorFee: market.maxLiquidatorFee(),
                price: price,
                size: market.marketSize(),
                skew: market.marketSkew(),
                skewScale: market.skewScale(),
                liquidationPremiumMultiplier: market.liquidationPremiumMultiplier(),
                liquidationBufferRatio: market.liquidationBufferRatio(),
                maxLiquidationDelta: market.maxLiquidationDelta(),
                maxPD: market.maxPD(),
                tradeFeeRatio: market.tradeFeeRatio(),
                burnAtTradePartOfTradeFee: market.burnAtTradePartOfTradeFee(),
                feeReceiverPartOfTradeFee: market.feeReceiverPartOfTradeFee(),
                feeReceiverPartOfLiquidationFee: market.feeReceiverPartOfLiquidationFee(),
                currentFundingRate: market.currentFundingRate(),
                currentFundingVelocity: market.currentFundingVelocity(),
                maxLeverage: market.maxLeverage(),
                maxMarketValue: market.maxMarketValue(),
                maxFundingVelocity: market.maxFundingVelocity(),
                longs: long,
                shorts: short,
                takerFee: market.takerFee(),
                makerFee: market.makerFee(),
                positionData: pd
            });
        }
    }
}
