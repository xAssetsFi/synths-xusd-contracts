// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Calculations} from "./_Calculations.sol";
import {SignedSafeMath} from "src/lib/SignedSafeMath.sol";

abstract contract PerpPosition is Calculations {
    using SignedSafeMath for int256;

    function _transferMargin(int256 marginDelta, uint256 price) internal 
    // notFlagged(sender)
    // onlyIfNotPendingOrder
    {
        // Transfer no tokens if marginDelta is 0
        uint256 absDelta = int256(marginDelta).abs();
        if (marginDelta > 0) {
            // A positive margin delta corresponds to a deposit, which will be burnt from their
            // sUSD balance and credited to their margin account.

            // Ensure we handle reclamation when burning tokens.
            provider().marketManager().burn(msg.sender, absDelta);
            // uint256 postReclamationAmount = _manager().burnSUSD(sender, absDelta);
            uint256 postReclamationAmount = absDelta;

            if (postReclamationAmount != absDelta) {
                // If balance was insufficient, the actual delta will be smaller
                marginDelta = int256(postReclamationAmount);
            }
        } else if (marginDelta < 0) {
            // A negative margin delta corresponds to a withdrawal, which will be minted into
            // their sUSD balance, and debited from their margin account.
            // _manager().issueSUSD(sender, absDelta);
            provider().marketManager().mint(msg.sender, absDelta);
        } else {
            // Zero delta is a no-op
            return;
        }

        PerpPosition memory position = _positions[msg.sender];

        uint256 remainingMargin = _updatePositionMargin(msg.sender, position, 0, price, marginDelta);

        // emitMarginTransferred(sender, marginDelta);
        emit MarginTransferred(msg.sender, remainingMargin, marginDelta);

        // emitPositionModified(
        //     position.id,
        //     sender,
        //     position.margin,
        //     position.size,
        //     0,
        //     price,
        //     _latestFundingIndex(),
        //     0,
        //     marketState.marketSkew()
        // );
    }

    function _modifyPosition(address positionOwner, int256 sizeDelta, uint256 desiredFillPrice)
        internal
    // onlyProxy
    // onlyIfNotPendingOrder
    {
        uint256 price = assetPrice();
        _recomputeFunding(price);
        _trade(
            positionOwner,
            TradeParams({
                sizeDelta: sizeDelta,
                oraclePrice: price,
                fillPrice: fillPrice(sizeDelta, price),
                desiredFillPrice: desiredFillPrice
            })
        );
    }

    function _liquidatePosition(address positionOwner, uint256 price) internal {
        PerpPosition memory position = _positions[positionOwner];

        // Get remaining margin for sending any leftover buffer to fee pool
        //
        // note: we do _not_ use `_remainingLiquidatableMargin` here as we want to send this premium to the fee pool
        // upon liquidation to give back to stakers.
        uint256 remainingMargin = remainingMargin(position, price);

        // Get fees to pay to flagger, liquidator and feepooland/or feePool)
        // Pay fee to flagger
        uint256 liquidationFee = _liquidationFee(position.size, price);

        // update remaining margin
        remainingMargin = remainingMargin > liquidationFee ? remainingMargin - liquidationFee : 0;

        // Record updates to market size and debt.
        marketSkew = int128(marketSkew - position.size);
        marketSize = uint128(marketSize - int256(position.size).abs());

        // marketState.setMarketSkew(int128(int256(marketState.marketSkew()).sub(positionSize)));
        // marketState.setMarketSize(
        //     uint128(uint256(marketState.marketSize()).sub(_abs(positionSize)))
        // );

        // uint256 fundingIndex = _latestFundingIndex();
        // _applyDebtCorrection(
        //     PerpPosition(0, uint64(fundingIndex), 0, uint128(price), 0),
        //     PerpPosition(
        //         0, position.lastFundingIndex, position.margin, position.lastPrice, position.size
        //     )
        // );

        // Issue the reward to the flagger.
        // _manager().issueSUSD(marketState.positionFlagger(account), flaggerFee);
        uint256 feeReceiverFee =
            uint256(int256(liquidationFee).multiplyDecimal(int256(feeReceiverPartOfLiquidationFee)));
        liquidationFee -= feeReceiverFee;
        provider().marketManager().mint(feeReceiver, feeReceiverFee);
        provider().marketManager().mint(msg.sender, liquidationFee);

        // Issue the reward to the liquidator (keeper).
        // if (liquidatorFee > 0) {
        //     provider().xusd().mint(msg.sender, liquidatorFee);
        // }

        // Pay the remaining to feePool
        if (remainingMargin > 0) {
            provider().marketManager().addRewardOnDebtShares(remainingMargin);
        }

        // Close the position itself.
        // marketState.deletePosition(account);
        delete _positions[positionOwner];

        emit PositionLiquidated(positionOwner, price, liquidationFee, feeReceiverFee);

        // Unflag position.
        // marketState.unflag(account);

        // emitPositionModified(
        //     positionId, account, 0, 0, 0, price, fundingIndex, 0, marketState.marketSkew()
        // );

        // emitPositionLiquidated(
        //     position.id,
        //     account,
        //     messageSender,
        //     position.size,
        //     price,
        //     flaggerFee,
        //     liquidatorFee,
        //     remainingMargin
        // );
    }
}
