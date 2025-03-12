// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Market, IMarket} from "src/platforms/perps/Market.sol";

/// @notice PerpDataProvider is a contract that provides data for perps
interface IPerpDataProvider {
    struct AggregatedPerpData {
        MarketData[] marketData;
    }

    struct MarketData {
        address market;
        bytes32 asset;
        bytes32 key;
        uint256 price;
        uint256 size;
        int256 skew;
        uint256 skewScale;
        int256 currentFundingRate;
        int256 currentFundingVelocity;
        uint256 maxLeverage;
        uint256 maxMarketValue;
        uint256 maxFundingVelocity;
        uint256 longs;
        uint256 shorts;
        uint256 baseFee;
        uint256 takerFee;
        uint256 makerFee;
        PositionData positionData;
    }

    struct PositionData {
        IMarket.PerpPosition position;
        int256 notionalValue;
        int256 profitLoss;
        int256 accruedFunding;
        uint256 remainingMargin;
        uint256 accessibleMargin;
        uint256 liquidationPrice;
        uint256 leverage;
        bool canLiquidate;
    }
}
