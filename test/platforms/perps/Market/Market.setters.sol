// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Setters is MarketSetup {
    bytes onlyOwnerRevertData;

    function _afterSetup() internal override {
        super._afterSetup();

        onlyOwnerRevertData =
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user);
    }

    function test_setMinInitialMargin() public {
        marketGold.setMinInitialMargin(100e18);
        assertEq(marketGold.minInitialMargin(), 100e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMinInitialMargin(100e18);
    }

    function test_setLiquidationFeeRatio() public {
        marketGold.setLiquidationFeeRatio(0.01e18);
        assertEq(marketGold.liquidationFeeRatio(), 0.01e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setLiquidationFeeRatio(0.01e18);
    }

    function test_setMinLiquidatorFee() public {
        marketGold.setMinLiquidatorFee(1e18);
        assertEq(marketGold.minLiquidatorFee(), 1e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMinLiquidatorFee(1e18);
    }

    function test_setMaxLiquidatorFee() public {
        marketGold.setMaxLiquidatorFee(100e18);
        assertEq(marketGold.maxLiquidatorFee(), 100e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMaxLiquidatorFee(100e18);
    }

    function test_setTakerFee() public {
        marketGold.setTakerFee(0.01e18);
        assertEq(marketGold.takerFee(), 0.01e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setTakerFee(0.01e18);
    }

    function test_setMakerFee() public {
        marketGold.setMakerFee(0.01e18);
        assertEq(marketGold.makerFee(), 0.01e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMakerFee(0.01e18);
    }

    function test_setMaxLeverage() public {
        marketGold.setMaxLeverage(10e18);
        assertEq(marketGold.maxLeverage(), 10e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMaxLeverage(10e18);
    }

    function test_setMaxMarketValue() public {
        marketGold.setMaxMarketValue(1000e18);
        assertEq(marketGold.maxMarketValue(), 1000e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMaxMarketValue(1000e18);
    }

    function test_setMaxFundingVelocity() public {
        marketGold.setMaxFundingVelocity(0.1e18);
        assertEq(marketGold.maxFundingVelocity(), 0.1e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMaxFundingVelocity(0.1e18);
    }

    function test_setSkewScale() public {
        marketGold.setSkewScale(1000e18);
        assertEq(marketGold.skewScale(), 1000e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setSkewScale(1000e18);
    }

    function test_setLiquidationPremiumMultiplier() public {
        marketGold.setLiquidationPremiumMultiplier(1e18);
        assertEq(marketGold.liquidationPremiumMultiplier(), 1e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setLiquidationPremiumMultiplier(1e18);
    }

    function test_setLiquidationBufferRatio() public {
        marketGold.setLiquidationBufferRatio(0.1e18);
        assertEq(marketGold.liquidationBufferRatio(), 0.1e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setLiquidationBufferRatio(0.1e18);
    }

    function test_setMaxLiquidationDelta() public {
        marketGold.setMaxLiquidationDelta(0.1e18);
        assertEq(marketGold.maxLiquidationDelta(), 0.1e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMaxLiquidationDelta(0.1e18);
    }

    function test_setMaxPD() public {
        marketGold.setMaxPD(0.1e18);
        assertEq(marketGold.maxPD(), 0.1e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setMaxPD(0.1e18);
    }

    function test_setTradeFeeRatio() public {
        marketGold.setTradeFeeRatio(0.01e18);
        assertEq(marketGold.tradeFeeRatio(), 0.01e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setTradeFeeRatio(0.01e18);
    }

    function test_setBurnAtTradePartOfTradeFee() public {
        marketGold.setBurnAtTradePartOfTradeFee(0.01e18);
        assertEq(marketGold.burnAtTradePartOfTradeFee(), 0.01e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setBurnAtTradePartOfTradeFee(0.01e18);
    }

    function test_setFeeReceiverPartOfTradeFee() public {
        marketGold.setFeeReceiverPartOfTradeFee(0.01e18);
        assertEq(marketGold.feeReceiverPartOfTradeFee(), 0.01e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setFeeReceiverPartOfTradeFee(0.01e18);
    }

    function test_setFeeReceiverPartOfLiquidationFee() public {
        marketGold.setFeeReceiverPartOfLiquidationFee(0.01e18);
        assertEq(marketGold.feeReceiverPartOfLiquidationFee(), 0.01e18);

        vm.prank(user);
        vm.expectRevert(onlyOwnerRevertData);
        marketGold.setFeeReceiverPartOfLiquidationFee(0.01e18);
    }
}
