// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IMarket} from "src/interface/platforms/perps/IMarket.sol";
import {ProviderKeeperUpgradeable} from "src/common/_ProviderKeeperUpgradeable.sol";

abstract contract State is ProviderKeeperUpgradeable, IMarket {
    // metadata
    bytes32 public marketKey;
    bytes32 public baseAsset;

    // global parameters
    uint256 public minInitialMargin; // Minimum initial margin required to open a position (e.g., 100e18 = 100 XUSD)
    uint256 public liquidationFeeRatio; // Fee ratio applied during liquidations (e.g., 0.01e18 = 1%)
    // uint256 public liquidationFee; // Fixed fee paid to the liquidator for executing a liquidation (e.g., 10e18 = 10 XUSD) //! Removed
    uint256 public minLiquidatorFee; // Minimum fee paid to the liquidator for executing a liquidation (e.g., 0 = 0 XUSD)
    uint256 public maxLiquidatorFee; // Maximum fee paid to the liquidator for executing a liquidation (e.g., 100e18 = 100 XUSD)

    // unique parameters for each market
    uint256 public takerFee; // Fee applied to taker orders (e.g., 0.02e18 = 0.02%)
    uint256 public makerFee; // Fee applied to maker orders (e.g., 0.01e18 = 0.01%)
    uint256 public maxLeverage; // Maximum leverage allowed for a position (e.g., 10e18 = 10x)
    uint256 public maxMarketValue; // Maximum value of all positions in the market (e.g., 1,000,000e18 = 1M sUSD)
    uint256 public maxFundingVelocity; // Maximum rate at which funding can change (e.g., 0.1e18 = 10%)
    uint256 public skewScale; // Scale used to normalize skew in the market (e.g., 1,000,000e18 = 1,000,000)
    uint256 public liquidationPremiumMultiplier; // ...
    uint256 public liquidationBufferRatio; // Buffer ratio to guarantee that position will have enough margin to be liquidated (e.g., 0.1e18 = 10%)
    uint256 public maxLiquidationDelta; // Maximum liquidation impact on market (e.g., 0.1e18 = 10%)
    uint256 public maxPD; // Maximum skew on market (e.g., 0.10e18 = 10%)
    // extra
    uint256 public tradeFeeRatio; // Fee applied to all trades (e.g., 0.01e18 = 0.01%)
    uint256 public burnAtTradePartOfTradeFee; // Burn some amount (from total trade fee `base+taker+maker`) (e.g., 0.01e18 = 0.01% from total fee, not from trade volume)
    uint256 public ownerPartOfTradeFee; // Some amount of fee (from total trade fee `base+taker+maker`) to be sent to the owner (e.g., 0.01e18 = 0.01%)
    uint256 public ownerPartOfLiquidationFee; // Some amount of fee (from liquidation fee) to be sent to the owner (e.g., 0.01e18 = 0.01%)

    // derived parameters
    uint256 public marketSize; // Total of all positions perps in the market
    int256 public marketSkew; // Delta between all long and short positions in the market
    uint32 public fundingLastRecomputed; // Last time funding was recomputed
    int128 public fundingRateLastRecomputed; // Last funding rate
    int128[] public fundingSequence; // Sequence of funding rates
    int128 public entryDebtCorrection; // ...
    uint64 public nextPositionId; // Next id for a position //? Will be collisions on different markets (mb encode market key in position id)

    mapping(address user => PerpPosition) internal _positions;

    mapping(address user => address executor) internal _allowedExecutors;

    function __State_init(bytes32 _marketKey, bytes32 _baseAsset) internal onlyInitializing {
        marketKey = _marketKey;
        baseAsset = _baseAsset;

        minInitialMargin = 100e18;
        // liquidationFee = 0e18;
        liquidationFeeRatio = 0.01e18;
        minLiquidatorFee = 0;
        maxLiquidatorFee = 100e18;

        takerFee = 0.0005e18;
        makerFee = 0.000001e18;
        maxLeverage = 10e18;
        maxMarketValue = 1_000_000e18;
        maxFundingVelocity = 1e18;
        skewScale = 100_000e18;
        liquidationPremiumMultiplier = 1.5e18;
        liquidationBufferRatio = 0.01e18;
        maxLiquidationDelta = 0.1e18;
        maxPD = 0.1e18;

        tradeFeeRatio = 0.015e18;
        burnAtTradePartOfTradeFee = 0.2e18;
        ownerPartOfTradeFee = 0.5e18;
        ownerPartOfLiquidationFee = 0.2e18;

        fundingSequence.push(0);
    }

    function approveExecutor(address executor) external {
        _allowedExecutors[msg.sender] = executor;
        emit ExecutorApproved(msg.sender, executor);
    }

    function getPerpPosition(address user) public view returns (PerpPosition memory) {
        return _positions[user];
    }

    function getFundingSequence() public view returns (int128[] memory) {
        return fundingSequence;
    }

    function setMinInitialMargin(uint256 newMinInitialMargin) external onlyOwner {
        minInitialMargin = newMinInitialMargin;
    }

    function setLiquidationFeeRatio(uint256 newLiquidationFeeRatio) external onlyOwner {
        liquidationFeeRatio = newLiquidationFeeRatio;
    }

    function setMinLiquidatorFee(uint256 newMinLiquidatorFee) external onlyOwner {
        minLiquidatorFee = newMinLiquidatorFee;
    }

    function setMaxLiquidatorFee(uint256 newMaxLiquidatorFee) external onlyOwner {
        maxLiquidatorFee = newMaxLiquidatorFee;
    }

    function setMakerFee(uint256 newMakerFee) external onlyOwner {
        makerFee = newMakerFee;
    }

    function setTakerFee(uint256 newTakerFee) external onlyOwner {
        takerFee = newTakerFee;
    }

    function setMaxLeverage(uint256 newMaxLeverage) external onlyOwner {
        maxLeverage = newMaxLeverage;
    }

    function setMaxMarketValue(uint256 newMaxMarketValue) external onlyOwner {
        maxMarketValue = newMaxMarketValue;
    }

    function setMaxFundingVelocity(uint256 newMaxFundingVelocity) external onlyOwner {
        maxFundingVelocity = newMaxFundingVelocity;
    }

    function setSkewScale(uint256 newSkewScale) external onlyOwner {
        skewScale = newSkewScale;
    }

    function setLiquidationPremiumMultiplier(uint256 newLiquidationPremiumMultiplier)
        external
        onlyOwner
    {
        liquidationPremiumMultiplier = newLiquidationPremiumMultiplier;
    }

    function setLiquidationBufferRatio(uint256 newLiquidationBufferRatio) external onlyOwner {
        liquidationBufferRatio = newLiquidationBufferRatio;
    }

    function setMaxLiquidationDelta(uint256 newMaxLiquidationDelta) external onlyOwner {
        maxLiquidationDelta = newMaxLiquidationDelta;
    }

    function setMaxPD(uint256 newMaxPD) external onlyOwner {
        maxPD = newMaxPD;
    }

    function setTradeFeeRatio(uint256 newTradeFeeRatio) external onlyOwner {
        tradeFeeRatio = newTradeFeeRatio;
    }

    function setBurnAtTradePartOfTradeFee(uint256 newBurnAtTradePartOfTradeFee)
        external
        onlyOwner
    {
        burnAtTradePartOfTradeFee = newBurnAtTradePartOfTradeFee;
    }

    function setOwnerPartOfTradeFee(uint256 newOwnerPartOfTradeFee) external onlyOwner {
        ownerPartOfTradeFee = newOwnerPartOfTradeFee;
    }

    function setOwnerPartOfLiquidationFee(uint256 newOwnerPartOfLiquidationFee)
        external
        onlyOwner
    {
        ownerPartOfLiquidationFee = newOwnerPartOfLiquidationFee;
    }
}
