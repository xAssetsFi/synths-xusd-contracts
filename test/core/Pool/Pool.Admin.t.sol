// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Pool.Setup.sol";

contract PoolV2 is Pool {
    function newFunction() public pure returns (uint256) {
        return 1;
    }
}

contract PoolAdminTest is PoolSetup {
    function test_addCollateralToken() public {
        address collateral = address(0x1);
        pool.addCollateralToken(collateral);
        assertTrue(pool.isCollateralToken(collateral));
    }

    function test_removeCollateralToken() public {
        address collateral = address(0x1);
        pool.addCollateralToken(collateral);
        pool.removeCollateralToken(collateral);
        assertFalse(pool.isCollateralToken(collateral));
    }

    function test_upgrade() public {
        vm.expectRevert();
        PoolV2(payable(address(pool))).newFunction();

        address newImplementation = address(new PoolV2());

        pool.upgradeToAndCall(newImplementation, "");

        assertEq(pool.implementation(), newImplementation);
        assertEq(PoolV2(payable(address(pool))).newFunction(), 1);
    }
}
