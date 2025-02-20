// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_PoolDataProvider.Setup.sol";

contract PoolDataProviderTest is PoolDataProviderSetup {
    uint256 amountSuppliedUSDC = 300 * 1e6;

    function _afterSetup() internal override {
        super._afterSetup();

        pool.setStabilityFee(0);

        pool.supply(address(usdc), amountSuppliedUSDC);
    }

    function test_maxWithdraw_allowAllAmount() public view {
        (uint256 tokenAmount, uint256 dollarAmount) =
            poolDataProvider.maxWithdraw(address(this), address(usdc));

        assertEq(tokenAmount, amountSuppliedUSDC);
        assertEq(dollarAmount, amountSuppliedUSDC);
    }

    function test_maxWithdraw_allowZeroAmount() public {
        uint256 maxBorrow = poolDataProvider.maxXUSDBorrow(address(this));
        pool.borrow(maxBorrow, type(uint256).max, address(this));

        (uint256 tokenAmount, uint256 dollarAmount) =
            poolDataProvider.maxWithdraw(address(this), address(usdc));

        assertEq(tokenAmount, 0);
        assertEq(dollarAmount, 0);
    }

    function test_maxBorrow() public view {
        assertEq(amountSuppliedUSDC, 300 * 1e6, "amountSuppliedUSDC != 300");

        uint256 maxBorrow = poolDataProvider.maxXUSDBorrow(address(this));
        assertEq(maxBorrow, 100 * 10 ** xusd.decimals());
    }

    function test_maxBorrow_ZeroAmount() public {
        uint256 maxBorrow = poolDataProvider.maxXUSDBorrow(address(this));

        pool.borrow(maxBorrow, type(uint256).max, address(this));

        maxBorrow = poolDataProvider.maxXUSDBorrow(address(this));
        assertEq(maxBorrow, 0);
    }

    function test_maxBorrow_withLowHf() public {
        uint256 maxBorrowBeforeBorrow = poolDataProvider.maxXUSDBorrow(address(this));

        pool.borrow(maxBorrowBeforeBorrow, type(uint256).max, address(this));

        diaOracle.setValue("USDC/USD", 1);

        assertLt(
            poolDataProvider.getHealthFactor(address(this)), pool.getMinHealthFactorForBorrow()
        );

        uint256 maxBorrow = poolDataProvider.maxXUSDBorrow(address(this));

        assertEq(maxBorrow, 0);
    }

    function test_healthFactor_noBorrow() public view {
        uint256 healthFactor = poolDataProvider.getHealthFactor(address(this));
        assertEq(healthFactor, type(uint256).max);
    }

    function test_healthFactor_withMaxBorrow() public {
        uint256 maxBorrow = poolDataProvider.maxXUSDBorrow(address(this));

        pool.borrow(maxBorrow, type(uint256).max, address(this));

        uint256 healthFactor = poolDataProvider.getHealthFactor(address(this));
        assertEq(healthFactor, pool.getMinHealthFactorForBorrow());
    }

    function test_getAggregatedPoolData_emptyState() public view {
        poolDataProvider.getAggregatedPoolData(address(1));
    }

    function test_getAggregatedPoolData_nonEmptyState() public {
        pool.supply(address(wbtc), 10 ** wbtc.decimals());
        pool.borrow(poolDataProvider.maxXUSDBorrow(address(this)), type(uint256).max, address(this));

        IPoolDataProvider.AggregatedPoolData memory data =
            poolDataProvider.getAggregatedPoolData(address(this));

        assertEq(data.paused, provider.isPaused());
        assertEq(data.oraclePrecision, oracleAdapter.precision());
        assertEq(data.poolData.pps, pool.pricePerShare());
        assertEq(data.poolData.debtSharesBalance, debtShares.balanceOf(address(this)));
        assertEq(data.poolData.minHealthFactorForBorrow, pool.getMinHealthFactorForBorrow());
        assertEq(data.poolData.liquidationRatio, pool.getCurrentLiquidationRatio());
        assertEq(data.poolData.collateralRatio, pool.getCurrentCollateralRatio());
        assertEq(data.poolData.cooldownPeriod, pool.cooldownPeriod());
        assertEq(data.poolData.healthFactorPrecision, WAD);
        assertEq(data.poolData.ratioPrecision, PRECISION);
    }

    function test_reCalcHF_supply_sameToken() public {
        pool.borrow(poolDataProvider.maxXUSDBorrow(address(this)), type(uint256).max, address(this));

        address collateralToken = address(usdc);
        int256 collateralAmount = int256(10 ** usdc.decimals());

        PoolDataProvider.ReCalcHfParams memory params =
            IPoolDataProvider.ReCalcHfParams(collateralToken, collateralAmount, 0);

        uint256 newHf = poolDataProvider.reCalcHf(address(this), params);
        assertGt(newHf, poolDataProvider.getHealthFactor(address(this)));
    }

    function test_reCalcHF_supply_diffToken() public {
        pool.borrow(poolDataProvider.maxXUSDBorrow(address(this)), type(uint256).max, address(this));

        address collateralToken = address(wbtc);
        int256 collateralAmount = int256(10 ** wbtc.decimals());

        PoolDataProvider.ReCalcHfParams memory params =
            IPoolDataProvider.ReCalcHfParams(collateralToken, collateralAmount, 0);

        uint256 newHf = poolDataProvider.reCalcHf(address(this), params);
        assertGt(newHf, poolDataProvider.getHealthFactor(address(this)));
    }

    function test_reCalcHF_withdraw() public {
        pool.borrow(1e18, type(uint256).max, address(this));

        address collateralToken = address(usdc);
        int256 withdrawAmount = -int256(10 ** usdc.decimals());

        PoolDataProvider.ReCalcHfParams memory params =
            IPoolDataProvider.ReCalcHfParams(collateralToken, withdrawAmount, 0);

        uint256 newHf = poolDataProvider.reCalcHf(address(this), params);
        assertLt(newHf, poolDataProvider.getHealthFactor(address(this)));
    }

    function test_reCalcHF_borrow() public {
        pool.borrow(1e18, type(uint256).max, address(this));

        int256 borrowAmount = int256(10 ** xusd.decimals());

        PoolDataProvider.ReCalcHfParams memory params =
            IPoolDataProvider.ReCalcHfParams(address(0), 0, borrowAmount);

        uint256 newHf = poolDataProvider.reCalcHf(address(this), params);
        assertLt(newHf, poolDataProvider.getHealthFactor(address(this)));
    }

    function test_reCalcHF_repay() public {
        pool.borrow(poolDataProvider.maxXUSDBorrow(address(this)), type(uint256).max, address(this));

        int256 repayAmount = -int256(10 ** xusd.decimals());

        PoolDataProvider.ReCalcHfParams memory params =
            IPoolDataProvider.ReCalcHfParams(address(0), 0, repayAmount);

        uint256 newHf = poolDataProvider.reCalcHf(address(this), params);
        assertGt(newHf, poolDataProvider.getHealthFactor(address(this)));
    }

    function test_findLiquidationOpportunity() public {
        pool.borrow(poolDataProvider.maxXUSDBorrow(address(this)), type(uint256).max, address(this));

        address user1 = _makeUser("user1");
        vm.startPrank(user1);
        wbtc.approve(address(pool), wbtc.balanceOf(user1));
        pool.supplyAndBorrow(address(wbtc), wbtc.balanceOf(user1), 1e18, type(uint256).max, user1);
        vm.stopPrank();

        pool.getPosition(user1);

        address[] memory users = new address[](2);
        users[0] = address(this);
        users[1] = user1;

        (address[] memory tokens, uint256[] memory shares) =
            poolDataProvider.findLiquidationOpportunity(users);

        assertEq(tokens.length, shares.length);
        assertEq(tokens.length, 2);

        assertEq(tokens[0], address(0));
        assertEq(shares[0], 0);

        assertEq(tokens[1], address(0));
        assertEq(shares[1], 0);

        diaOracle.setValue("USDC/USD", 1e7);

        (tokens, shares) = poolDataProvider.findLiquidationOpportunity(users);

        assertEq(tokens.length, shares.length);
        assertEq(tokens.length, 2);

        assertEq(tokens[0], address(usdc));
        assertNotEq(shares[0], 0);

        assertEq(tokens[1], address(0));
        assertEq(shares[1], 0);

        diaOracle.setValue("WBTC/USD", uint128(1));

        (tokens, shares) = poolDataProvider.findLiquidationOpportunity(users);

        assertEq(tokens.length, shares.length);
        assertEq(tokens.length, 2);

        assertEq(tokens[0], address(usdc));
        assertNotEq(shares[0], 0);

        assertEq(tokens[1], address(wbtc));
        assertNotEq(shares[1], 0);
    }
}
