// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IMarket {
    // If margin/size are positive, the p is long; if negative then it is short.
    struct PerpPosition {
        int128 size;
        uint128 margin;
        uint128 lastPrice;
        uint64 lastFundingIndex;
        uint64 id;
    }

    // convenience struct for passing params between p modification helper functions
    struct TradeParams {
        int256 sizeDelta;
        uint256 oraclePrice;
        uint256 fillPrice;
        uint256 desiredFillPrice;
    }

    /// @notice Initializes the market contract with provider, market key, and base asset.
    /// @param _provider The address of the protocol provider.
    /// @param _marketKey The unique key for this market.
    /// @param _baseAsset The base asset identifier for this market.
    function initialize(address _provider, bytes32 _marketKey, bytes32 _baseAsset) external;

    /// @notice Returns the unique key for this market.
    function marketKey() external view returns (bytes32);

    /// @notice Returns the base asset identifier for this market.
    function baseAsset() external view returns (bytes32);

    /* ======== WRITE ======== */

    /// @notice Liquidates a position if it is eligible for liquidation.
    /// @param positionOwner The address of the position owner to liquidate.
    function liquidatePosition(address positionOwner) external;

    /// @notice Adds or removes margin from the sender's position.
    /// @param marginDelta The amount of margin to add (positive) or remove (negative).
    function transferMargin(int256 marginDelta) external;

    /// @notice Modifies the sender's position size by the given delta at the current fill price.
    /// @param sizeDelta The change in position size (positive for increase, negative for decrease).
    function modifyPosition(int256 sizeDelta) external;

    /// @notice Modifies the sender's position size by the given delta, specifying a desired fill price.
    /// @param sizeDelta The change in position size (positive for increase, negative for decrease).
    /// @param desiredFillPrice The maximum (for buy) or minimum (for sell) acceptable fill price.
    function modifyPosition(int256 sizeDelta, uint256 desiredFillPrice) external;

    /// @notice Modifies a position on behalf of another user (executor pattern).
    /// @param positionOwner The address of the position owner.
    /// @param sizeDelta The change in position size.
    /// @param price The desired fill price.
    function modifyPositionFromExecutor(address positionOwner, int256 sizeDelta, uint256 price)
        external;

    /// @notice Withdraws all accessible margin from the sender's position.
    function withdrawAllMargin() external;

    /// @notice Closes the sender's position at the specified desired fill price.
    /// @param desiredFillPrice The minimum acceptable fill price for closing the position.
    function closePosition(uint256 desiredFillPrice) external;

    /// @notice Approves an executor to modify the sender's position.
    /// @param executor The address to approve as executor.
    function approveExecutor(address executor) external;

    /* ======== READ ======== */

    /// @notice Returns the current oracle price of the base asset.
    function assetPrice() external view returns (uint256);

    /// @notice Returns the total market size (sum of all open positions).
    function marketSize() external view returns (uint256);

    /// @notice Returns the total market debt at a given price.
    /// @param price The price to use for debt calculation.
    function marketDebt(uint256 price) external view returns (uint256);

    /// @notice Returns the sequence of funding rates for the market.
    function getFundingSequence() external view returns (int128[] memory);

    /// @notice Returns the current funding rate for the market.
    function currentFundingRate() external view returns (int256);

    /// @notice Returns the sizes of the long and short sides of the market.
    /// @return long The total size of long positions.
    /// @return short The total size of short positions.
    function marketSizes() external view returns (uint256 long, uint256 short);

    /// @notice Calculates the fill price for a given size delta and oracle price.
    /// @param sizeDelta The change in position size.
    /// @param price The oracle price.
    /// @return The calculated fill price.
    function fillPrice(int256 sizeDelta, uint256 price) external view returns (uint256);

    /// @notice Returns the unrecorded funding amount at a given price.
    /// @param price The price to use for funding calculation.
    function unrecordedFunding(uint256 price) external view returns (int256);

    /// @notice Calculates the notional value for a given position size and price.
    /// @param size The position size.
    /// @param price The price of the asset.
    /// @return The notional value.
    function notionalValue(int256 size, uint256 price) external view returns (int256);

    /// @notice Calculates the order fee for a given trade.
    /// @param tradeParams The parameters of the trade.
    /// @return The fee amount.
    function orderFee(TradeParams memory tradeParams) external view returns (uint256);

    /// @notice Returns the perpetual position details for a given user.
    /// @param positionOwner The address of the position owner.
    /// @return The PerpPosition struct.
    function getPerpPosition(address positionOwner) external view returns (PerpPosition memory);

    /// @notice Returns the accessible margin for a position at a given price.
    /// @param p The position struct.
    /// @param price The price of the asset.
    /// @return The accessible margin.
    function accessibleMargin(PerpPosition memory p, uint256 price)
        external
        view
        returns (uint256);

    /// @notice Returns the remaining margin for a position at a given price.
    /// @param p The position struct.
    /// @param price The price of the asset.
    /// @return The remaining margin.
    function remainingMargin(PerpPosition memory p, uint256 price)
        external
        view
        returns (uint256);

    /// @notice Calculates the profit or loss for a position at a given price.
    /// @param p The position struct.
    /// @param price The price of the asset.
    /// @return The profit or loss.
    function profitLoss(PerpPosition memory p, uint256 price) external view returns (int256);

    /// @notice Returns the accrued funding for a position at a given price.
    /// @param p The position struct.
    /// @param price The price of the asset.
    /// @return The accrued funding.
    function accruedFunding(PerpPosition memory p, uint256 price) external view returns (int256);

    /// @notice Checks if a position can be liquidated at a given price.
    /// @param p The position struct.
    /// @param price The price of the asset.
    /// @return True if the position can be liquidated, false otherwise.
    function canLiquidate(PerpPosition memory p, uint256 price) external view returns (bool);

    /// @notice Returns the liquidation price for a given position.
    /// @param p The position struct.
    /// @return The liquidation price.
    function liquidationPrice(PerpPosition memory p) external view returns (uint256);

    /// @notice Returns the required margin to avoid liquidation for a given position size and price.
    /// @param positionSize The size of the position.
    /// @param price The price of the asset.
    /// @return The required liquidation margin.
    function liquidationMargin(int256 positionSize, uint256 price)
        external
        view
        returns (uint256);

    /// @notice Calculates the current leverage for a position.
    /// @param size The position size.
    /// @param price The price of the asset.
    /// @param remainingMargin The remaining margin in the position.
    /// @return The leverage value.
    function currentLeverage(int256 size, uint256 price, uint256 remainingMargin)
        external
        view
        returns (uint256);

    /// @notice Returns the new position and fee after a trade.
    /// @param p The current position struct.
    /// @param tradeParams The parameters of the trade.
    /// @return newPosition The new position struct.
    /// @return fee The fee charged for the trade.
    function postTradeDetails(PerpPosition memory p, TradeParams memory tradeParams)
        external
        view
        returns (PerpPosition memory newPosition, uint256 fee);

    event MarginTransferred(
        address indexed user,
        uint256 price,
        uint256 remainingMargin,
        int256 marginDelta,
        int256 profitLoss
    );
    event PositionModified(
        address indexed user,
        int256 sizeDelta,
        uint256 fillPrice,
        int256 remainingSize,
        int256 profitLoss,
        uint256 fee,
        uint256 burnFee,
        uint256 feeReceiverFee
    );
    event PositionLiquidated(
        address indexed user, uint256 oraclePrice, uint256 liquidationFee, uint256 feeReceiverFee
    );
    event ExecutorApproved(address user, address executor);
    event FeeReceiverUpdated(address newFeeReceiver);

    error CanLiquidate();
    error CannotLiquidate();
    error MaxMarketSizeExceeded();
    error MaxLeverageExceeded();
    error InsufficientMargin();
    error NilOrder();
    error NoPositionOpen();
    error PriceTooVolatile();
    error PriceImpactToleranceExceeded(uint256 fillPrice, uint256 desiredFillPrice);
    error NotAllowedExecutor();
}
