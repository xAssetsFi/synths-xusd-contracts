// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Pool.Setup.sol";

contract PoolViewTest is PoolSetup {
    function test_collateralRatio() public view {
        assertEq(pool.getCurrentCollateralRatio(), 30000);
    }

    function test_liquidationRatio() public view {
        assertEq(pool.getCurrentLiquidationRatio(), 12000);
    }

    function test_liquidationPenaltyPercentagePoint() public view {
        assertEq(pool.liquidationPenaltyPercentagePoint(), 500);
    }

    function test_liquidationBonusPercentagePoint() public view {
        assertEq(pool.liquidationBonusPercentagePoint(), 500);
    }

    function test_minHealthFactorForBorrow() public view {
        assertEq(pool.getMinHealthFactorForBorrow(), 2.5 ether);
    }

    function test_calculateDeductionsWhileLiquidation() public view {
        uint256 xusdAmount = 1e18;

        uint256 usdcPrice = oracleAdapter.getPrice(address(usdc));
        uint256 oraclePrecision = oracleAdapter.precision();

        uint256 tokenDecimalsDelta = 10 ** (18 - usdc.decimals());

        (uint256 base, uint256 bonus, uint256 penalty) =
            pool.calculateDeductionsWhileLiquidation(address(usdc), xusdAmount);

        assertEq(base, xusdAmount * oraclePrecision / usdcPrice / tokenDecimalsDelta);
        assertEq(bonus, base * pool.liquidationBonusPercentagePoint() / PRECISION);
        assertEq(penalty, base * pool.liquidationPenaltyPercentagePoint() / PRECISION);
    }
}
