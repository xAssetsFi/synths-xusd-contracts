// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {PerpPosition} from "src/modules/market/_Position.sol";

import {SignedSafeMath} from "src/lib/SignedSafeMath.sol";

import {IMarket} from "src/interface/platforms/perps/IMarket.sol";

contract Market is PerpPosition {
    using SignedSafeMath for int256;

    function initialize(address _provider, bytes32 _marketKey, bytes32 _baseAsset)
        external
        initializer
    {
        __ProviderKeeper_init(_provider);
        __State_init(_marketKey, _baseAsset);

        _registerInterface(type(IMarket).interfaceId);
    }

    function transferMarginAndModifyPosition(int256 marginDelta, int256 sizeDelta)
        external
        noPaused
    {
        uint256 price = assetPrice();
        _recomputeFunding(price);
        _transferMargin(marginDelta, price);
        _modifyPosition(msg.sender, sizeDelta, fillPrice(sizeDelta, price));
    }

    /*
     * Alter the amount of margin in a position. A positive input triggers a deposit; a negative one, a
     * withdrawal. The margin will be burnt or issued directly into/out of the caller's sUSD wallet.
     * Reverts on deposit if the caller lacks a sufficient sUSD balance.
     * Reverts on withdrawal if the amount to be withdrawn would expose an open position to liquidation.
     */
    function transferMargin(int256 marginDelta) external noPaused {
        uint256 price = assetPrice();
        _recomputeFunding(price);
        _transferMargin(marginDelta, price);
    }

    /*
     * Submit an order to close a position.
     */

    function closePosition(uint256 desiredFillPrice) external noPaused {
        int256 size = _positions[msg.sender].size;
        if (size == 0) revert NoPositionOpen();

        _modifyPosition(msg.sender, -size, desiredFillPrice);
    }

    /*
     * Adjust the sender's position size.
     * Reverts if the resulting position is too large, outside the max leverage, or is liquidating.
     */
    function modifyPosition(int256 sizeDelta, uint256 desiredFillPrice) external noPaused {
        _modifyPosition(msg.sender, sizeDelta, desiredFillPrice);
    }

    function modifyPosition(int256 sizeDelta) external noPaused {
        _modifyPosition(msg.sender, sizeDelta, fillPrice(sizeDelta, assetPrice()));
    }

    function modifyPositionFromExecutor(
        address positionOwner,
        int256 sizeDelta,
        uint256 desiredFillPrice
    ) external noPaused {
        if (_allowedExecutors[positionOwner] != msg.sender) {
            revert NotAllowedExecutor();
        }

        _modifyPosition(positionOwner, sizeDelta, desiredFillPrice);
    }

    /*
     * Withdraws all accessible margin in a position. This will leave some remaining margin
     * in the account if the caller has a position open. Equivalent to `transferMargin(-accessibleMargin(sender))`.
     */

    function withdrawAllMargin() external noPaused {
        uint256 price = assetPrice();
        _recomputeFunding(price);
        int256 marginDelta = -int256(accessibleMargin(_positions[msg.sender], price));
        _transferMargin(marginDelta, price);
    }

    /*
     * Liquidate a position if its remaining margin is below the liquidation fee. This succeeds if and only if
     * `canLiquidate(account)` is true, and reverts otherwise.
     * Upon liquidation, the position will be closed, and the liquidation fee minted into the liquidator's account.
     */
    function liquidatePosition(address positionOwner)
        external
        noPaused /*onlyProxy flagged(account)*/
    {
        uint256 price = assetPrice();
        _recomputeFunding(price);

        if (!canLiquidate(_positions[positionOwner], price)) {
            revert CannotLiquidate();
        }

        // Check price impact of liquidation
        require(
            maxLiquidationDelta
                > uint256(
                    int256(_positions[positionOwner].size).signedAbs().divideDecimal(int256(skewScale))
                ),
            "price impact of liquidation exceeded"
        );

        // Check Instantaneous P/D
        require(
            maxPD > uint256(int256(marketSkew).signedAbs().divideDecimal(int256(skewScale))),
            "instantaneous P/D exceeded"
        );

        // Liquidate and get remaining margin
        _liquidatePosition(positionOwner, price);
    }
}
