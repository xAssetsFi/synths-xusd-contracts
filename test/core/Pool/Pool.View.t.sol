// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Pool.Setup.sol";

contract PoolViewTest is PoolSetup {
    function test_collateralRatio() public view {
        assertEq(pool.collateralRatio(), 30000);
    }

    function test_liquidationRatio() public view {
        assertEq(pool.liquidationRatio(), 12000);
    }

    function test_liquidationPenaltyPercentagePoint() public view {
        assertEq(pool.liquidationPenaltyPercentagePoint(), 500);
    }

    function test_liquidationBonusPercentagePoint() public view {
        assertEq(pool.liquidationBonusPercentagePoint(), 1000);
    }

    function test_minHealthFactorForBorrow() public view {
        assertEq(pool.getMinHealthFactorForBorrow(), 2.5 ether);
    }
}
