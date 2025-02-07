// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

import {CalculationsInitParams} from "src/core/pool/modules/_Calculations.sol";

contract SettersTest is Setup {
    address a = makeAddr("a");
    uint256 u256 = 1;
    uint32 u32 = 1;
    string s = "";

    /* ======== PROVIDER ======== */

    function test_setExchanger() public {
        Exchanger newExchanger = _deployExchanger(address(this), address(provider), 1, 1, 1, 1);

        provider.setExchanger(address(newExchanger));

        assertEq(address(provider.exchanger()), address(newExchanger));
    }

    function test_setPool() public {
        CalculationsInitParams memory params = CalculationsInitParams({
            collateralRatio: 1,
            liquidationRatio: 1,
            liquidationPenaltyPercentagePoint: 1,
            liquidationBonusPercentagePoint: 1,
            loanFee: 1,
            stabilityFee: 1,
            cooldownPeriod: 1
        });

        Pool newPool = _deployPool(
            address(this), address(provider), address(wxfi), address(debtShares), params
        );

        provider.setPool(address(newPool));

        assertEq(address(provider.pool()), address(newPool));
    }

    function test_setOracle() public {
        DiaOracleAdapter newOracle =
            _deployDiaOracleAdapter(address(this), address(provider), address(diaOracle));

        provider.setOracle(address(newOracle));

        assertEq(address(provider.oracle()), address(newOracle));
    }

    function test_setXUSD() public {
        Synth newXUSD = _deployXUSD(address(this), address(provider), "xUSD", "xUSD");

        provider.setXUSD(address(newXUSD));

        assertEq(address(provider.xusd()), address(newXUSD));
    }

    /* ======== EXCHANGER ======== */

    function test_setSettlementDelay() public {
        exchanger.setSettlementDelay(u32);
        assertEq(exchanger.settlementDelay(), u32);
    }

    function test_setSwapFee() public {
        exchanger.setSwapFee(u256);
        assertEq(exchanger.swapFee(), u256);
    }

    function test_setFeeReceiver() public {
        exchanger.setFeeReceiver(a);
        assertEq(exchanger.feeReceiver(), a);
    }

    function test_setBurntAtSwap() public {
        exchanger.setBurntAtSwap(u256);
        assertEq(exchanger.burntAtSwap(), u256);
    }

    function test_setRewarderFee() public {
        exchanger.setRewarderFee(u256);
        assertEq(exchanger.rewarderFee(), u256);
    }

    /* ======== ORACLE ADAPTER ======== */

    function test_setKey() public {
        oracleAdapter.setKey(a, s);
        assertEq(oracleAdapter.keys(a), s);
    }

    function test_setDiaOracle() public {
        oracleAdapter.setDiaOracle(a);
        assertEq(address(oracleAdapter.diaOracle()), a);
    }

    function test_setFallbackOracle() public {
        DiaOracleAdapter fallbackOracle =
            _deployDiaOracleAdapter(address(this), address(provider), address(diaOracle));

        oracleAdapter.setFallbackOracle(address(fallbackOracle));

        assertEq(address(oracleAdapter.fallbackOracle()), address(fallbackOracle));
    }

    /* ======== POOL ======== */

    function test_setCollateralRatio() public {
        pool.setCollateralRatio(u32);
        assertEq(pool.collateralRatio(), u32);
    }

    function test_setLiquidationRatio() public {
        pool.setLiquidationRatio(u32);
        assertEq(pool.liquidationRatio(), u32);
    }

    function test_setLiquidationPenaltyPercentagePoint() public {
        pool.setLiquidationPenaltyPercentagePoint(u32);
        assertEq(pool.liquidationPenaltyPercentagePoint(), u32);
    }

    function test_setLiquidationBonusPercentagePoint() public {
        pool.setLiquidationBonusPercentagePoint(u32);
        assertEq(pool.liquidationBonusPercentagePoint(), u32);
    }

    function test_setLoanFee() public {
        pool.setLoanFee(u32);
        assertEq(pool.loanFee(), u32);
    }

    function test_setStabilityFee() public {
        pool.setStabilityFee(u32);
        assertEq(pool.stabilityFee(), u32);
    }

    function test_setCooldownPeriod() public {
        pool.setCooldownPeriod(u32);
        assertEq(pool.cooldownPeriod(), u32);
    }
}
