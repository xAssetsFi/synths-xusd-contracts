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

    function initialize(address _provider, bytes32 _marketKey, bytes32 _baseAsset) external;

    function marketKey() external view returns (bytes32);

    function baseAsset() external view returns (bytes32);

    /* ======== WRITE ======== */

    function liquidatePosition(address positionOwner) external;

    function transferMargin(int256 marginDelta) external;

    function modifyPosition(int256 sizeDelta) external;

    function modifyPosition(int256 sizeDelta, uint256 desiredFillPrice) external;

    function modifyPositionFromExecutor(address positionOwner, int256 sizeDelta, uint256 price)
        external;

    function withdrawAllMargin() external;

    function closePosition(uint256 desiredFillPrice) external;

    function approveExecutor(address executor) external;

    /* ======== READ ======== */

    function assetPrice() external view returns (uint256);

    function marketSize() external view returns (uint256);

    function marketDebt(uint256 price) external view returns (uint256);

    function getFundingSequence() external view returns (int128[] memory);

    function currentFundingRate() external view returns (int256);

    function marketSizes() external view returns (uint256 long, uint256 short);

    function fillPrice(int256 sizeDelta, uint256 price) external view returns (uint256);

    function unrecordedFunding(uint256 price) external view returns (int256);

    function notionalValue(int256 size, uint256 price) external view returns (int256);

    function orderFee(TradeParams memory tradeParams) external view returns (uint256);

    function getPerpPosition(address positionOwner) external view returns (PerpPosition memory);

    function accessibleMargin(PerpPosition memory p, uint256 price)
        external
        view
        returns (uint256);

    function remainingMargin(PerpPosition memory p, uint256 price)
        external
        view
        returns (uint256);

    function profitLoss(PerpPosition memory p, uint256 price) external view returns (int256);

    function accruedFunding(PerpPosition memory p, uint256 price) external view returns (int256);

    function canLiquidate(PerpPosition memory p, uint256 price) external view returns (bool);

    function liquidationPrice(PerpPosition memory p) external view returns (uint256);

    function liquidationMargin(int256 positionSize, uint256 price)
        external
        view
        returns (uint256);

    function currentLeverage(int256 size, uint256 price, uint256 remainingMargin)
        external
        view
        returns (uint256);

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
    error PriceImpactToleranceExceeded();
    error NotAllowedExecutor();
}
