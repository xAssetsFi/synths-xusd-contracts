// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OnlyOwnerTest is Setup {
    address notOwner = address(0x2222222);

    address a = makeAddr("a");
    uint256 u = 1;
    string s = "";

    function _afterSetup() internal override {
        provider.transferOwnership(notOwner);
        oracleAdapter.transferOwnership(notOwner);
        pool.transferOwnership(notOwner);
        exchanger.transferOwnership(notOwner);

        debtShares.transferOwnership(notOwner);
        poolDataProvider.transferOwnership(notOwner);
    }

    /* ======== PROVIDER ======== */

    function test_upgradeToAndCall_revertIfNotOwner() public {
        _expectRevert();
        provider.upgradeToAndCall(a, "");
    }

    function test_setExchanger_revertIfNotOwner() public {
        _expectRevert();
        provider.setExchanger(a);
    }

    function test_setPool_revertIfNotOwner() public {
        _expectRevert();
        provider.setPool(a);
    }

    function test_setOracle_revertIfNotOwner() public {
        _expectRevert();
        provider.setOracle(a);
    }

    function test_setXUSD_revertIfNotOwner() public {
        _expectRevert();
        provider.setXUSD(a);
    }

    function test_pause_revertIfNotOwner() public {
        _expectRevert();
        provider.pause();
    }

    function test_unpause_revertIfNotOwner() public {
        _expectRevert();
        provider.unpause();
    }

    /* ======== EXCHANGER ======== */

    function test_createSynth_revertIfNotOwner() public {
        _expectRevert();
        exchanger.createSynth(a, s, s);
    }

    function test_addNewSynth_revertIfNotOwner() public {
        _expectRevert();
        exchanger.addNewSynth(a);
    }

    function test_removeSynth_revertIfNotOwner() public {
        _expectRevert();
        exchanger.removeSynth(a);
    }

    function test_setFinishSwapDelay_revertIfNotOwner() public {
        _expectRevert();
        exchanger.setFinishSwapDelay(u);
    }

    function test_setSwapFee_revertIfNotOwner() public {
        _expectRevert();
        exchanger.setSwapFee(u);
    }

    function test_setFeeReceiver_revertIfNotOwner() public {
        _expectRevert();
        exchanger.setFeeReceiver(a);
    }

    function test_setBurntAtSwap_revertIfNotOwner() public {
        _expectRevert();
        exchanger.setBurntAtSwap(u);
    }

    function test_setRewarderFee_revertIfNotOwner() public {
        _expectRevert();
        exchanger.setRewarderFee(u);
    }

    /* ======== ORACLE ADAPTER ======== */

    function test_setKey_revertIfNotOwner() public {
        _expectRevert();
        oracleAdapter.setKey(a, s);
    }

    function test_setDiaOracle_revertIfNotOwner() public {
        _expectRevert();
        oracleAdapter.setDiaOracle(a);
    }

    function test_setFallbackOracle_revertIfNotOwner() public {
        _expectRevert();
        oracleAdapter.setFallbackOracle(a);
    }

    /* ======== POOL ======== */

    function test_addCollateralToken_revertIfNotOwner() public {
        _expectRevert();
        pool.addCollateralToken(a);
    }

    function test_removeCollateralToken_revertIfNotOwner() public {
        _expectRevert();
        pool.removeCollateralToken(a);
    }

    function test_setCollateralRatio_revertIfNotOwner() public {
        _expectRevert();
        pool.setCollateralRatio(0, 1 weeks);
    }

    function test_setLiquidationRatio_revertIfNotOwner() public {
        _expectRevert();
        pool.setLiquidationRatio(0, 1 weeks);
    }

    function test_setLiquidationPenaltyPercentagePoint_revertIfNotOwner() public {
        _expectRevert();
        pool.setLiquidationPenaltyPercentagePoint(0);
    }

    function test_setLiquidationBonusPercentagePoint_revertIfNotOwner() public {
        _expectRevert();
        pool.setLiquidationBonusPercentagePoint(0);
    }

    function test_setLoanFee_revertIfNotOwner() public {
        _expectRevert();
        pool.setLoanFee(0);
    }

    function test_setStabilityFee_revertIfNotOwner() public {
        _expectRevert();
        pool.setStabilityFee(0);
    }

    function test_setCooldownPeriod_revertIfNotOwner() public {
        _expectRevert();
        pool.setCooldownPeriod(0);
    }

    /* ======== INTERNAL ======== */

    function _expectRevert() internal {
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this))
        );
    }
}
