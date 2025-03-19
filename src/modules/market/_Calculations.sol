// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {State} from "./_State.sol";
import {IOracleAdapter} from "src/interface/IOracleAdapter.sol";
import {SignedSafeMath} from "src/lib/SignedSafeMath.sol";

abstract contract Calculations is State {
    using SignedSafeMath for int256;

    /*
     * Returns the pSkew = skew / skewScale capping the pSkew between [-1, 1].
     */
    function _proportionalSkew() internal view returns (int256) {
        int256 pSkew = marketSkew.divideDecimal(int256(skewScale));

        // Ensures the proportionalSkew is between -1 and 1.
        return SignedSafeMath.min(SignedSafeMath.max(-int256(WAD), pSkew), int256(WAD));
    }

    function _proportionalElapsed() internal view returns (int256) {
        return int256(block.timestamp - fundingLastRecomputed).divideDecimal(1 days);
    }

    function currentFundingVelocity() public view returns (int256) {
        return _proportionalSkew().multiplyDecimal(int256(maxFundingVelocity));
    }

    /*
     * @dev Retrieves the _current_ funding rate given the current market conditions.
     *
     * This is used during funding computation _before_ the market is modified (e.g. closing or
     * opening a position). However, called via the `currentFundingRate` view, will return the
     * 'instantaneous' funding rate. It's similar but subtle in that velocity now includes the most
     * recent skew modification.
     *
     * There is no variance in computation but will be affected based on outside modifications to
     * the market skew, max funding velocity, price, and time delta.
     */
    function currentFundingRate() public view returns (int256) {
        // calculations:
        //  - velocity          = proportional_skew * max_funding_velocity
        //  - proportional_skew = skew / skew_scale
        //
        // example:
        //  - prev_funding_rate     = 0
        //  - prev_velocity         = 0.0025
        //  - time_delta            = 29,000s
        //  - max_funding_velocity  = 0.025 (2.5%)
        //  - skew                  = 300
        //  - skew_scale            = 10,000
        //
        // note: prev_velocity just refs to the velocity _before_ modifying the market skew.
        //
        // funding_rate = prev_funding_rate + prev_velocity * (time_delta / seconds_in_day)
        // funding_rate = 0 + 0.0025 * (29,000 / 86,400)
        //              = 0 + 0.0025 * 0.33564815
        //              = 0.00083912

        return int256(fundingRateLastRecomputed)
            + currentFundingVelocity().multiplyDecimal(_proportionalElapsed());
    }

    function unrecordedFunding(uint256 price) public view returns (int256) {
        int256 nextFundingRate = currentFundingRate();
        // note the minus sign: funding flows in the opposite direction to the skew.
        int256 avgFundingRate =
            -(int256(fundingRateLastRecomputed).add(nextFundingRate)).divideDecimal(int256(WAD * 2));
        return avgFundingRate.multiplyDecimal(_proportionalElapsed()).multiplyDecimal(int256(price));
    }

    /*
     * The new entry in the funding sequence, appended when funding is recomputed. It is the sum of the
     * last entry and the unrecorded funding, so the sequence accumulates running total over the market's lifetime.
     */
    function _nextFundingEntry(uint256 price) internal view returns (int256) {
        return int256(fundingSequence[_latestFundingIndex()]).add(unrecordedFunding(price));
    }

    function _netFundingPerUnit(uint256 startIndex, uint256 price) internal view returns (int256) {
        // Compute the net difference between start and end indices.
        return _nextFundingEntry(price).sub(fundingSequence[startIndex]);
    }

    function _latestFundingIndex() internal view returns (uint256) {
        return fundingSequence.length - 1;
    }

    /* ---------- PerpPosition Details ---------- */

    /*
     * Determines whether a change in a position's size would violate the max market value constraint.
     */
    function _orderSizeTooLarge(uint256 maxSize, int256 oldSize, int256 newSize)
        internal
        view
        returns (bool)
    {
        // Allow users to reduce an order no matter the market conditions.
        if (SignedSafeMath.sameSide(oldSize, newSize) && newSize.abs() <= oldSize.abs()) {
            return false;
        }

        // Either the user is flipping sides, or they are increasing an order on the same side they're already on;
        // we check that the side of the market their order is on would not break the limit.
        int256 newSkew = int256(marketSkew).sub(oldSize).add(newSize);
        int256 newMarketSize =
            int256(uint256(marketSize)).sub(oldSize.signedAbs()).add(newSize.signedAbs());

        int256 newSideSize;
        if (0 < newSize) {
            // long case: marketSize + skew
            //            = (|longSize| + |shortSize|) + (longSize + shortSize)
            //            = 2 * longSize
            newSideSize = newMarketSize.add(newSkew);
        } else {
            // short case: marketSize - skew
            //            = (|longSize| + |shortSize|) - (longSize + shortSize)
            //            = 2 * -shortSize
            newSideSize = newMarketSize.sub(newSkew);
        }

        // newSideSize still includes an extra factor of 2 here, so we will divide by 2 in the actual condition
        if (maxSize < newSideSize.abs() / 2) {
            return true;
        }

        return false;
    }

    function notionalValue(int256 positionSize, uint256 price) public pure returns (int256 value) {
        return positionSize.multiplyDecimal(int256(price));
    }

    function profitLoss(PerpPosition memory position, uint256 price)
        public
        pure
        returns (int256 pnl)
    {
        int256 priceShift = int256(price).sub(int256(uint256(position.lastPrice)));
        return int256(position.size).multiplyDecimal(priceShift);
    }

    function accruedFunding(PerpPosition memory position, uint256 price)
        public
        view
        returns (int256 funding)
    {
        uint256 lastModifiedIndex = position.lastFundingIndex;
        if (lastModifiedIndex == 0) {
            return 0; // The position does not exist -- no funding.
        }
        int256 net = _netFundingPerUnit(lastModifiedIndex, price);
        return int256(position.size).multiplyDecimal(net);
    }

    /*
     * The initial margin of a position, plus any PnL and funding it has accrued. The resulting value may be negative.
     */
    function _marginPlusProfitFunding(PerpPosition memory position, uint256 price)
        internal
        view
        returns (int256)
    {
        int256 funding = accruedFunding(position, price);
        return int256(uint256(position.margin)).add(profitLoss(position, price)).add(funding);
    }

    /*
     * The value in a position's margin after a deposit or withdrawal, accounting for funding and profit.
     * If the resulting margin would be negative or below the liquidation threshold, an appropriate error is returned.
     * If the result is not an error, callers of this function that use it to update a position's margin
     * must ensure that this is accompanied by a corresponding debt correction update, as per `_applyDebtCorrection`.
     */
    function _recomputeMarginWithDelta(
        PerpPosition memory position,
        uint256 price,
        int256 marginDelta
    ) internal view returns (uint256 margin) {
        int256 newMargin = _marginPlusProfitFunding(position, price).add(marginDelta);
        if (newMargin < 0) {
            revert InsufficientMargin();
        }

        uint256 uMargin = uint256(newMargin);
        int256 positionSize = int256(position.size);
        // minimum margin beyond which position can be liquidated
        uint256 lMargin = liquidationMargin(positionSize, price);
        if (positionSize != 0 && uMargin <= lMargin) {
            revert CanLiquidate();
        }

        return uMargin;
    }

    function remainingMargin(PerpPosition memory position, uint256 price)
        public
        view
        returns (uint256)
    {
        int256 remaining = _marginPlusProfitFunding(position, price);

        // If the margin went past zero, the position should have been liquidated - return zero remaining margin.
        return uint256(SignedSafeMath.max(0, remaining));
    }

    function accessibleMargin(PerpPosition memory position, uint256 price)
        public
        view
        returns (uint256)
    {
        // Ugly solution to rounding safety: leave up to an extra tenth of a cent in the account/leverage
        // This should guarantee that the value returned here can always be withdrawn, but there may be
        // a little extra actually-accessible value left over, depending on the position size and margin.
        uint256 milli = WAD / 1000;
        int256 maxLeverage = int256(maxLeverage).sub(int256(milli));
        uint256 inaccessible = notionalValue(position.size, price).divideDecimal(maxLeverage).abs();

        // If the user has a position open, we'll enforce a min initial margin requirement.
        if (0 < inaccessible) {
            if (inaccessible < minInitialMargin) {
                inaccessible = minInitialMargin;
            }
            inaccessible = inaccessible + milli;
        }

        uint256 remaining = remainingMargin(position, price);
        if (remaining <= inaccessible) {
            return 0;
        }

        return remaining - inaccessible;
    }

    /**
     * The fee charged from the margin during liquidation. Fee is proportional to position size
     * but is between _minKeeperFee() and _maxKeeperFee() expressed in sUSD to prevent underincentivising
     * liquidations of small positions, or overpaying.
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in sUSD fixed point decimal units
     * @return lFee liquidation fee to be paid to liquidator in sUSD fixed point decimal units
     */
    function _liquidationFee(int256 positionSize, uint256 price)
        internal
        view
        returns (uint256 lFee)
    {
        // size * price * fee-ratio
        int256 proportionalFee = positionSize.signedAbs().multiplyDecimal(int256(price))
            .multiplyDecimal(int256(liquidationFeeRatio));
        uint256 cappedProportionalFee = uint256(proportionalFee) > maxLiquidatorFee
            ? maxLiquidatorFee
            : uint256(proportionalFee);

        // max(proportionalFee, minFee) - to prevent not incentivising liquidations enough
        return cappedProportionalFee > minLiquidatorFee ? cappedProportionalFee : minLiquidatorFee; // not using _max() helper because it's for signed ints
    }

    /**
     * The minimal margin at which liquidation can happen.
     * Is the sum of liquidationBuffer, liquidationFee (for flagger) and liquidationFee (for liquidator)
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in sUSD fixed point decimal units
     * @return lMargin liquidation margin to maintain in sUSD fixed point decimal units
     * @dev The liquidation margin contains a buffer that is proportional to the position
     * size. The buffer should prevent liquidation happening at negative margin (due to next price being worse)
     * so that stakers would not leak value to liquidators through minting rewards that are not from the
     * account's margin.
     */
    function liquidationMargin(int256 positionSize, uint256 price)
        public
        view
        returns (uint256 lMargin)
    {
        int256 liquidationBuffer = positionSize.signedAbs().multiplyDecimal(int256(price))
            .multiplyDecimal(int256(liquidationBufferRatio));
        return uint256(liquidationBuffer) + _liquidationFee(positionSize, price); // + liquidationFee;
    }

    /*
     * The price at which a position is subject to liquidation; otherwise the price at which the user's remaining
     * margin has run out. When they have just enough margin left to pay a liquidator, then they are liquidated.
     * If a position is long, then it is safe as long as the current price is above the liquidation price; if it is
     * short, then it is safe whenever the current price is below the liquidation price.
     * A position's accurate liquidation price can move around slightly due to accrued funding.
     */
    function liquidationPrice(PerpPosition memory position) external view returns (uint256 price) {
        if (position.size == 0) return 0;

        // fundingPerUnit
        //  price = lastPrice + (liquidationMargin - margin) / positionSize - netAccrued
        //
        // A position can be liquidated whenever:
        //  remainingMargin <= liquidationMargin
        //
        // Hence, expanding the definition of remainingMargin the exact price at which a position can be liquidated is:
        //
        //  margin + profitLoss + funding = liquidationMargin
        //  substitute with: profitLoss = (price - last-price) * positionSize
        //  and also with: funding = netFundingPerUnit * positionSize
        //  we get: margin + (price - last-price) * positionSize + netFundingPerUnit * positionSize = liquidationMargin
        //  moving around: price = lastPrice + (liquidationMargin - margin - liqPremium) / positionSize - netFundingPerUnit
        uint256 oraclePrice = assetPrice();

        int256 result = int256(uint256(position.lastPrice)).add(
            int256(liquidationMargin(position.size, oraclePrice)).sub(
                int256(uint256(position.margin)).sub(
                    int256(_liquidationPremium(position.size, oraclePrice))
                )
            ).divideDecimal(position.size)
        ).sub(_netFundingPerUnit(position.lastFundingIndex, oraclePrice));

        // If the user has leverage less than 1, their liquidation price may actually be negative; return 0 instead.
        return uint256(SignedSafeMath.max(0, result));
    }

    /**
     * @dev This is the additional premium we charge upon liquidation.
     *
     * Similar to fillPrice, but we disregard the skew (by assuming it's zero). Which is basically the calculation
     * when we compute as if taking the position from 0 to x. In practice, the premium component of the
     * liquidation will just be (size / skewScale) * (size * price).
     *
     * It adds a configurable multiplier that can be used to increase the margin that goes to feePool.
     *
     * For instance, if size of the liquidation position is 100, oracle price is 1200 and skewScale is 1M then,
     *
     *  size    = abs(-100)
     *          = 100
     *  premium = 100 / 1000000 * (100 * 1200) * multiplier
     *          = 12 * multiplier
     *  if multiplier is set to 1
     *          = 12 * 1 = 12
     *
     * @param positionSize Size of the position we want to liquidate
     * @param currentPrice The current oracle price (not fillPrice)
     * @return The premium to be paid upon liquidation in sUSD
     */
    function _liquidationPremium(int256 positionSize, uint256 currentPrice)
        internal
        view
        returns (uint256)
    {
        if (positionSize == 0) {
            return 0;
        }

        // note: this is the same as fillPrice() where the skew is 0.
        uint256 notional = notionalValue(positionSize, currentPrice).abs();

        return uint256(
            positionSize.signedAbs().divideDecimal(int256(skewScale)).multiplyDecimal(
                int256(notional)
            ).multiplyDecimal(int256(liquidationPremiumMultiplier))
        );
    }

    /*
     * @dev Similar to remainingMargin except it accounts for the premium and fees to be paid upon liquidation.
     */
    function _remainingLiquidatableMargin(PerpPosition memory position, uint256 price)
        internal
        view
        returns (uint256)
    {
        int256 remaining = _marginPlusProfitFunding(position, price).sub(
            int256(_liquidationPremium(position.size, price))
        );
        return uint256(SignedSafeMath.max(0, remaining));
    }

    function canLiquidate(PerpPosition memory position, uint256 price) public view returns (bool) {
        // No liquidating empty positions.
        if (position.size == 0) return false;

        return _remainingLiquidatableMargin(position, price)
            <= liquidationMargin(int256(position.size), price);
    }

    function currentLeverage(int256 size, uint256 price, uint256 remainingMargin_)
        public
        pure
        returns (uint256 leverage)
    {
        // No position is open, or it is ready to be liquidated; leverage goes to nil
        if (remainingMargin_ == 0) return 0;

        return notionalValue(size, price).divideDecimal(int256(remainingMargin_)).abs();
    }

    function orderFee(TradeParams memory params) public view returns (uint256 fee) {
        // usd value of the difference in position (using the p/d-adjusted price).

        int256 notionalDiff = params.sizeDelta.multiplyDecimal(int256(params.fillPrice));

        // minimum fee to pay regardless (due to dynamic fees).
        uint256 baseFee = uint256(notionalDiff.signedAbs().multiplyDecimal(int256(tradeFeeRatio)));

        // does this trade keep the skew on one side?
        if (SignedSafeMath.sameSide(marketSkew + params.sizeDelta, marketSkew)) {
            // use a flat maker/taker fee for the entire size depending on whether the skew is increased or reduced.
            //
            // if the order is submitted on the same side as the skew (increasing it) - the taker fee is charged.
            // otherwise if the order is opposite to the skew, the maker fee is charged.
            uint256 staticRate =
                SignedSafeMath.sameSide(notionalDiff, marketSkew) ? takerFee : makerFee;
            return baseFee + uint256(notionalDiff.signedAbs().multiplyDecimal(int256(staticRate)));
        }

        // this trade flips the skew.
        //
        // the proportion of size that moves in the direction after the flip should not be considered
        // as a maker (reducing skew) as it's now taking (increasing skew) in the opposite direction. hence,
        // a different fee is applied on the proportion increasing the skew.

        // proportion of size that's on the other direction
        int256 takerSize =
            (marketSkew + params.sizeDelta).signedAbs().divideDecimal(params.sizeDelta);
        int256 makerSize = int256(WAD) - takerSize;
        uint256 takerFee = uint256(
            notionalDiff.signedAbs().multiplyDecimal(takerSize).multiplyDecimal(int256(takerFee))
        );
        uint256 makerFee = uint256(
            notionalDiff.signedAbs().multiplyDecimal(makerSize).multiplyDecimal(int256(makerFee))
        );

        return baseFee + takerFee + makerFee;
    }

    /// Uses the exchanger to get the dynamic fee (SIP-184) for trading from sUSD to baseAsset
    /// this assumes dynamic fee is symmetric in direction of trade.
    /// @dev this is a pretty expensive action in terms of execution gas as it queries a lot
    ///   of past rates from oracle. Shouldn't be much of an issue on a rollup though.
    // function _dynamicFeeRate() internal pure returns (uint256 feeRate, bool tooVolatile) {
    //     return _exchanger.dynamicFeeRateForExchange(sUSD, uint256(uint160(baseAsset)));
    // }

    function postTradeDetails(PerpPosition memory oldPos, TradeParams memory params)
        public
        view
        returns (PerpPosition memory newPosition, uint256 fee)
    {
        // Reverts if the user is trying to submit a size-zero order.
        if (params.sizeDelta == 0) {
            revert NilOrder();
        }

        // The order is not submitted if the user's existing position needs to be liquidated.
        if (canLiquidate(oldPos, params.oraclePrice)) {
            revert CanLiquidate();
        }

        // get the dynamic fee rate SIP-184
        // (uint256 dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        // if (tooVolatile) {
        //     revert PriceTooVolatile();
        // }

        // calculate the total fee for exchange
        fee = orderFee(params); // ,dynamicFeeRate);

        // Deduct the fee.
        // It is an error if the realised margin minus the fee is negative or subject to liquidation.
        uint256 newMargin = _recomputeMarginWithDelta(oldPos, params.fillPrice, -int256(fee));

        // construct new position
        PerpPosition memory newPos = PerpPosition({
            id: oldPos.id,
            lastFundingIndex: uint64(_latestFundingIndex()),
            margin: uint128(newMargin),
            lastPrice: uint128(params.fillPrice),
            size: int128(int256(oldPos.size).add(params.sizeDelta))
        });

        // always allow to decrease a position, otherwise a margin of minInitialMargin can never
        // decrease a position as the price goes against them.
        // we also add the paid out fee for the minInitialMargin because otherwise minInitialMargin
        // is never the actual minMargin, because the first trade will always deduct
        // a fee (so the margin that otherwise would need to be transferred would have to include the future
        // fee as well, making the UX and definition of min-margin confusing).
        bool positionDecreasing = SignedSafeMath.sameSide(oldPos.size, newPos.size)
            && int256(newPos.size).abs() < int256(oldPos.size).abs();
        if (!positionDecreasing) {
            // minMargin + fee <= margin is equivalent to minMargin <= margin - fee
            // except that we get a nicer error message if fee > margin, rather than arithmetic overflow.
            if (newPos.margin + fee < minInitialMargin) {
                revert InsufficientMargin();
            }
        }

        // check that new position margin is above liquidation margin
        // (above, in _recomputeMarginWithDelta() we checked the old position, here we check the new one)
        //
        // Liquidation margin is considered without a fee (but including premium), because it wouldn't make sense to allow
        // a trade that will make the position liquidatable.
        //
        // note: we use `oraclePrice` here as `liquidationPremium` calcs premium based not current skew.
        uint256 liqPremium = _liquidationPremium(newPos.size, params.oraclePrice);
        uint256 liqMargin = liquidationMargin(newPos.size, params.oraclePrice) + liqPremium;
        if (newMargin <= liqMargin) {
            revert CanLiquidate();
        }

        // Check that the maximum leverage is not exceeded when considering new margin including the paid fee.
        // The paid fee is considered for the benefit of UX of allowed max leverage, otherwise, the actual
        // max leverage is always below the max leverage parameter since the fee paid for a trade reduces the margin.
        // We'll allow a little extra headroom for rounding errors.
        {
            // stack too deep
            int256 leverage = int256(newPos.size).multiplyDecimal(int256(params.fillPrice))
                .divideDecimal(int256(newMargin + fee));
            if (maxLeverage + WAD / 100 < leverage.abs()) {
                revert MaxLeverageExceeded();
            }
        }

        // Check that the order isn't too large for the markets.
        if (_orderSizeTooLarge(maxMarketValue, oldPos.size, newPos.size)) {
            revert MaxMarketSizeExceeded();
        }

        return (newPos, fee);
    }

    /* ---------- Utilities ---------- */

    /*
     * The current base price from the oracle, and whether that price was invalid. Zero prices count as invalid.
     * Public because used both externally and internally
     * Price scale is 18 decimals
     */
    function assetPrice() public view returns (uint256 price) {
        IOracleAdapter diaOracleAdapter = provider().oracle();

        price = diaOracleAdapter.getPrice(address(uint160(uint256(baseAsset))));

        uint256 scaleToWad = 1e18 / diaOracleAdapter.precision();

        return price * scaleToWad;

        // (price, invalid) = _exchangeRates().rateAndInvalid(_baseAsset());
        // // Ensure we catch uninitialised rates or suspended state / synth
        // invalid = invalid || price == 0 || _systemStatus().synthSuspended(_baseAsset());
        // return (price, invalid);
    }

    /*
     * @dev SIP-279 fillPrice price at which a trade is executed against accounting for how this position's
     * size impacts the skew. If the size contracts the skew (reduces) then a discount is applied on the price
     * whereas expanding the skew incurs an additional premium.
     */
    function fillPrice(int256 size, uint256 price) public view returns (uint256) {
        int256 pdBefore = marketSkew.divideDecimal(int256(skewScale));
        int256 pdAfter = marketSkew.add(size).divideDecimal(int256(skewScale));
        int256 priceBefore = int256(price).add(int256(price).multiplyDecimal(pdBefore));
        int256 priceAfter = int256(price).add(int256(price).multiplyDecimal(pdAfter));

        // How is the p/d-adjusted price calculated using an example:
        //
        // price      = $1200 USD (oracle)
        // size       = 100
        // skew       = 0
        // skew_scale = 1,000,000 (1M)
        //
        // Then,
        //
        // pd_before = 0 / 1,000,000
        //           = 0
        // pd_after  = (0 + 100) / 1,000,000
        //           = 100 / 1,000,000
        //           = 0.0001
        //
        // price_before = 1200 * (1 + pd_before)
        //              = 1200 * (1 + 0)
        //              = 1200
        // price_after  = 1200 * (1 + pd_after)
        //              = 1200 * (1 + 0.0001)
        //              = 1200 * (1.0001)
        //              = 1200.12
        // Finally,
        //
        // fill_price = (price_before + price_after) / 2
        //            = (1200 + 1200.12) / 2
        //            = 1200.06
        return uint256(priceBefore.add(priceAfter).divideDecimal(int256(WAD * 2)));
    }

    /*
     * Alter the debt correction to account for the net result of altering a position.
     */
    function _applyDebtCorrection(PerpPosition memory newPosition, PerpPosition memory oldPosition)
        internal
    {
        int256 newCorrection = _positionDebtCorrection(newPosition);
        int256 oldCorrection = _positionDebtCorrection(oldPosition);
        entryDebtCorrection =
            int128(int256(entryDebtCorrection).add(newCorrection).sub(oldCorrection));
    }

    /*
     * The impact of a given position on the debt correction.
     */
    function _positionDebtCorrection(PerpPosition memory position) internal view returns (int256) {
        /**
         * This method only returns the correction term for the debt calculation of the position, and not it's
         *     debt. This is needed for keeping track of the marketDebt() in an efficient manner to allow O(1) marketDebt
         *     calculation in marketDebt().
         *
         *     Explanation of the full market debt calculation from the SIP https://sips.synthetix.io/sips/sip-80/:
         *
         *     The overall market debt is the sum of the remaining margin in all positions. The intuition is that
         *     the debt of a single position is the value withdrawn upon closing that position.
         *
         *     single position remaining margin = initial-margin + profit-loss + accrued-funding =
         *         = initial-margin + q * (price - last-price) + q * funding-accrued-per-unit
         *         = initial-margin + q * price - q * last-price + q * (funding - initial-funding)
         *
         *     Total debt = sum ( position remaining margins )
         *         = sum ( initial-margin + q * price - q * last-price + q * (funding - initial-funding) )
         *         = sum( q * price ) + sum( q * funding ) + sum( initial-margin - q * last-price - q * initial-funding )
         *         = skew * price + skew * funding + sum( initial-margin - q * ( last-price + initial-funding ) )
         *         = skew (price + funding) + sum( initial-margin - q * ( last-price + initial-funding ) )
         *
         *     The last term: sum( initial-margin - q * ( last-price + initial-funding ) ) being the position debt correction
         *         that is tracked with each position change using this method.
         *
         *     The first term and the full debt calculation using current skew, price, and funding is calculated globally in marketDebt().
         */
        return int256(uint256(position.margin)).sub(
            int256(position.size).multiplyDecimal(
                int256(uint256(position.lastPrice)).add(fundingSequence[position.lastFundingIndex])
            )
        );
    }

    // function _assertFillPrice(uint256 fillPrice, uint256 desiredFillPrice, int256 sizeDelta)
    //     internal
    //     pure
    //     returns (uint256)
    // {
    //     bool isError = sizeDelta > 0 ? fillPrice > desiredFillPrice : fillPrice < desiredFillPrice;

    //     if (isError) {
    //         revert PriceImpactToleranceExceeded();
    //     }

    //     return fillPrice;
    // }

    function _recomputeFunding(uint256 price) internal returns (uint256 lastIndex) {
        uint256 sequenceLengthBefore = fundingSequence.length;

        int256 fundingRate = currentFundingRate();
        int256 funding = _nextFundingEntry(price);
        fundingSequence.push(int128(funding));
        fundingLastRecomputed = uint32(block.timestamp);
        fundingRateLastRecomputed = int128(fundingRate);

        // emitFundingRecomputed(
        //     funding, fundingRate, sequenceLengthBefore, marketState.fundingLastRecomputed()
        // );

        return sequenceLengthBefore;
    }

    // updates the stored position margin in place (on the stored position)
    function _updatePositionMargin(
        address account,
        PerpPosition memory position,
        int256 orderSizeDelta,
        uint256 price,
        int256 marginDelta
    ) internal {
        PerpPosition memory oldPosition = position;
        // Determine new margin, ensuring that the result is positive.
        uint256 margin = _recomputeMarginWithDelta(oldPosition, price, marginDelta);

        // Update the debt correction.
        uint256 fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            PerpPosition(position.size, uint128(margin), uint128(price), uint64(fundingIndex), 0),
            PerpPosition(
                position.size, position.margin, position.lastPrice, position.lastFundingIndex, 0
            )
        );

        // Update the account's position with the realised margin.
        position.margin = uint128(margin);

        // We only need to update their funding/PnL details if they actually have a position open
        if (position.size != 0) {
            position.lastPrice = uint128(price);
            position.lastFundingIndex = uint64(fundingIndex);

            // The user can always decrease their margin if they have no position, or as long as:
            //   * the resulting margin would not be lower than the liquidation margin or min initial margin
            //     * liqMargin accounting for the liqPremium
            if (marginDelta < 0) {
                // note: We .add `liqPremium` to increase the req margin to avoid entering into liquidation
                uint256 liqPremium = _liquidationPremium(position.size, price);
                uint256 liqMargin = liquidationMargin(position.size, price) + liqPremium;

                if (margin <= liqMargin) {
                    revert InsufficientMargin();
                }

                // `marginDelta` can be decreasing (due to e.g. fees). However, price could also have moved in the
                // opposite direction resulting in a loss. A reduced remainingMargin to calc currentLeverage can
                // put the position above maxLeverage.
                //
                // To account for this, a check on `positionDecreasing` ensures that we can always perform this action
                // so long as we're reducing the position size and not liquidatable.
                int256 newPositionSize = int256(position.size).add(orderSizeDelta);
                bool positionDecreasing = SignedSafeMath.sameSide(position.size, newPositionSize)
                    && newPositionSize.abs() < int256(position.size).abs();

                if (!positionDecreasing) {
                    if (maxLeverage < currentLeverage(position.size, price, margin)) {
                        revert MaxLeverageExceeded();
                    }

                    if (margin < minInitialMargin) {
                        revert InsufficientMargin();
                    }
                }
                // _revertIfError(
                //     _maxLeverage(_marketKey()) < _abs(currentLeverage(position, price, margin)),
                //     Status.MaxLeverageExceeded
                // );
                // _revertIfError(margin < _minInitialMargin(), Status.InsufficientMargin);
                // }
            }
        }

        // persist position changes
        _positions[account] = position;
        // marketState.updatePosition(
        //     account,
        //     position.id,
        //     position.lastFundingIndex,
        //     position.margin,
        //     position.lastPrice,
        //     position.size
        // );
    }

    function _trade(address sender, TradeParams memory params) internal /*notFlagged(sender)*/ {
        PerpPosition memory position = _positions[sender];
        PerpPosition memory oldPosition = PerpPosition({
            id: position.id,
            lastFundingIndex: position.lastFundingIndex,
            margin: position.margin,
            lastPrice: position.lastPrice,
            size: position.size
        });

        // Compute the new position after performing the trade
        (PerpPosition memory newPosition, uint256 fee) = postTradeDetails(oldPosition, params);

        // _assertFillPrice(params.fillPrice, params.desiredFillPrice, params.sizeDelta);

        bool isError = params.sizeDelta > 0
            ? params.fillPrice > params.desiredFillPrice
            : params.fillPrice < params.desiredFillPrice;

        if (isError) revert PriceImpactToleranceExceeded();

        // Update the aggregated market size and skew with the new order size
        // marketState.setMarketSkew(
        //     int128(int256(marketState.marketSkew()).add(newPosition.size).sub(oldPosition.size))
        // );
        // marketState.setMarketSize(
        //     uint128(
        //         uint256(marketState.marketSize()).add(_abs(newPosition.size)).sub(
        //             _abs(oldPosition.size)
        //         )
        //     )
        // );
        marketSkew = int128(marketSkew + newPosition.size - oldPosition.size);
        marketSize =
            uint128(marketSize + int256(newPosition.size).abs() - int256(oldPosition.size).abs());

        uint256 burnFee;
        uint256 ownerFee;

        // Send the fee to the fee pool
        if (fee > 0) {
            // _manager().payFee(fee);
            burnFee = uint256(int256(fee).multiplyDecimal(int256(burnAtTradePartOfTradeFee)));
            ownerFee = uint256(int256(fee).multiplyDecimal(int256(ownerPartOfTradeFee)));

            fee -= burnFee + ownerFee;

            provider().marketManager().mint(owner(), ownerFee);
            // we don't need to actually burn the fee, we only need to decrease the minting amount
            provider().marketManager().addRewardOnDebtShares(fee);
        }
        // emit tracking code event
        // if (params.trackingCode != bytes32(0)) {
        //     emitPerpsTracking(
        //         params.trackingCode, _baseAsset(), _marketKey(), params.sizeDelta, fee
        //     );
        // }

        // Update the margin, and apply the resulting debt correction
        position.margin = newPosition.margin;
        _applyDebtCorrection(newPosition, oldPosition);

        // Record the trade
        uint64 id = oldPosition.id;
        uint256 fundingIndex = _latestFundingIndex();
        if (newPosition.size == 0) {
            // If the position is being closed, we no longer need to track these details.
            delete position.id;
            delete position.size;
            delete position.lastPrice;
            delete position.lastFundingIndex;
        } else {
            if (oldPosition.size == 0) {
                // New positions get new ids.
                id = nextPositionId++;
            }
            position.id = id;
            position.size = newPosition.size;
            position.lastPrice = uint128(params.fillPrice);
            position.lastFundingIndex = uint64(fundingIndex);
        }

        // persist position changes
        _positions[sender] = position;
        // marketState.updatePosition(
        //     sender,
        //     position.id,
        //     position.lastFundingIndex,
        //     position.margin,
        //     position.lastPrice,
        //     position.size
        // );

        emit PositionModified(
            sender, params.sizeDelta, params.fillPrice, newPosition.size, fee, burnFee, ownerFee
        );

        // emit the modification event
        // emitPositionModified(
        //     id,
        //     sender,
        //     newPosition.margin,
        //     newPosition.size,
        //     params.sizeDelta,
        //     params.fillPrice,
        //     fundingIndex,
        //     fee,
        //     marketState.marketSkew()
        // );
    }

    function marketDebt(uint256 price) public view returns (uint256) {
        // short circuit and also convenient during setup
        if (marketSkew == 0 && entryDebtCorrection == 0) {
            // if these are 0, the resulting calculation is necessarily zero as well
            return 0;
        }
        // see comment explaining this calculation in _positionDebtCorrection()
        int256 priceWithFunding = int256(price).add(_nextFundingEntry(price));
        int256 totalDebt =
            int256(marketSkew).multiplyDecimal(priceWithFunding).add(entryDebtCorrection);
        return totalDebt > 0 ? uint256(totalDebt) : 0;
    }

    /*
     * Sizes of the long and short sides of the market (in sUSD)
     */
    function marketSizes() external view returns (uint256 long, uint256 short) {
        return (
            int256(marketSize).add(marketSkew).div(2).abs(),
            int256(marketSize).sub(marketSkew).div(2).abs()
        );
    }
}
