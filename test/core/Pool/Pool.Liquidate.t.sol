// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Pool.Setup.sol";

import {IPool} from "src/interface/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolLiquidateTest is PoolSetup {
    uint256 amountSupplied = 375 * 1e6;
    uint256 amountBorrowed = 100 ether;
    uint256 receiverShares = 100 ether;

    uint128 dePegUsdcPrice = 4e7 - 1;

    function _afterSetup() internal override {
        super._afterSetup();

        pool.supplyAndBorrow(
            address(usdc), amountSupplied, amountBorrowed, type(uint256).max, address(this)
        );

        diaOracle.setValue("USDC/USD", dePegUsdcPrice);
    }

    function testFuzz_liquidate(uint256 amount) public {
        vm.assume(amount > 1e4 && amount <= receiverShares / 2);

        uint256 hfBefore = pool.getHealthFactor(address(this));
        pool.liquidate(address(this), address(usdc), 0, amount, address(this));
        uint256 hfAfter = pool.getHealthFactor(address(this));

        assertGt(hfAfter, hfBefore);
    }

    function testFuzz_liquidate_getDataFromPoolDataProvider(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1e18);

        diaOracle.setValue("USDC/USD", uint128(oracleAdapter.precision()));

        pool.supply(address(wxfi), amount);

        diaOracle.setValue("USDC/USD", uint128(3.95e7));

        address[] memory users = new address[](1);
        users[0] = address(this);

        (address[] memory tokens, uint256[] memory shares) =
            poolDataProvider.findLiquidationOpportunity(users);

        uint256 hfBefore = pool.getHealthFactor(address(this));
        uint256 xusdAmountBefore = xusd.balanceOf(address(this));
        uint256 collateralAmountBefore = IERC20(tokens[0]).balanceOf(address(this));

        pool.liquidate(address(this), tokens[0], 0, shares[0], address(this));

        uint256 hfAfter = pool.getHealthFactor(address(this));
        uint256 xusdAmountAfter = xusd.balanceOf(address(this));
        uint256 collateralAmountAfter = IERC20(tokens[0]).balanceOf(address(this));

        assertGt(hfAfter, hfBefore);
        assertLt(xusdAmountAfter, xusdAmountBefore);
        assertGt(collateralAmountAfter, collateralAmountBefore);
    }

    function test_stabilityFeeAccountInLiquidation() public {
        skip(1 weeks);
        _updateOraclePrice();
        diaOracle.setValue("USDC/USD", dePegUsdcPrice);

        uint256 liquidationAmount = receiverShares / 2;

        uint256 stabilityFeeBefore = pool.calculateStabilityFee(address(this));
        uint256 debtSharesBefore = debtShares.balanceOf(address(this));

        pool.liquidate(address(this), address(usdc), 0, liquidationAmount, address(this));

        uint256 stabilityFeeAfter = pool.calculateStabilityFee(address(this));
        uint256 debtSharesAfter = debtShares.balanceOf(address(this));

        assertEq(stabilityFeeAfter, 0);
        assertLt(stabilityFeeAfter, stabilityFeeBefore);

        assertGt(debtSharesAfter + liquidationAmount, debtSharesBefore);
    }

    function test_liquidate_ShouldRevertIfMinAmountIsNotMet() public {
        uint256 liquidationAmount = receiverShares / 2;

        vm.expectPartialRevert(IPool.TokenAmountTooLow.selector);
        pool.liquidate(
            address(this), address(usdc), type(uint256).max, liquidationAmount, address(this)
        );
    }
}
