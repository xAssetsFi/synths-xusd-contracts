// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Pool.Setup.sol";

import {IPool} from "src/interface/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolRepayTest is PoolSetup {
    uint256 amountSuppliedXFI = 1e22;
    uint256 amountSuppliedUSDC = 1e20;
    uint256 amountBorrowed = 1e18;
    uint256 amountSharesReceived;

    function _afterSetup() internal override {
        super._afterSetup();
        pool.supply(address(wxfi), amountSuppliedXFI);
        pool.supply(address(usdc), amountSuppliedUSDC);
        pool.borrow(amountBorrowed, address(this));

        amountSharesReceived = debtShares.balanceOf(address(this));

        assertEq(xusd.balanceOf(address(this)), amountBorrowed);
        assertEq(xusd.totalSupply(), amountBorrowed);
    }

    function testFuzz_repay_notFullAmount(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= amountSharesReceived);

        uint256 balanceSharesBefore = debtShares.balanceOf(address(this));
        uint256 balanceXUSDBefore = xusd.balanceOf(address(this));

        pool.repay(amount);

        uint256 balanceSharesAfter = debtShares.balanceOf(address(this));
        uint256 balanceXUSDAfter = xusd.balanceOf(address(this));

        assertEq(balanceSharesBefore - balanceSharesAfter, amount);
        assertLt(balanceXUSDAfter, balanceXUSDBefore);
    }

    function test_repay_wholeAmount() public {
        pool.repay(amountSharesReceived);

        assertEq(xusd.balanceOf(address(this)), 0);
        assertEq(xusd.totalSupply(), 0);

        assertEq(debtShares.balanceOf(address(this)), 0);
    }

    function testFuzz_repay_moreThanDebt(uint256 amount) public {
        vm.assume(amount > amountSharesReceived);
        vm.assume(amount != type(uint256).max);

        pool.repay(amount);

        assertEq(debtShares.balanceOf(address(this)), 0);
    }

    function test_repay_maxUint() public {
        IPool.Position memory position = pool.getPosition(address(this));
        uint256 collateral0BalanceBefore =
            IERC20(position.collaterals[0].token).balanceOf(address(this));

        pool.repay(type(uint256).max);

        assertEq(debtShares.balanceOf(address(this)), 0);

        uint256 collateral0BalanceAfter =
            IERC20(position.collaterals[0].token).balanceOf(address(this));

        assertGt(collateral0BalanceAfter, collateral0BalanceBefore);

        vm.expectRevert();
        pool.getPosition(address(this));
    }

    function test_stabilityFeeAccountInRepay() public {
        _skipAndUpdateOraclePrice(1 weeks);

        uint256 stabilityFeeBefore = pool.calculateStabilityFee(address(this));
        uint256 debtSharesBefore = debtShares.balanceOf(address(this));

        pool.repay(amountSharesReceived);

        uint256 stabilityFeeAfter = pool.calculateStabilityFee(address(this));
        uint256 debtSharesAfter = debtShares.balanceOf(address(this));

        assertEq(stabilityFeeAfter, 0);
        assertLt(stabilityFeeAfter, stabilityFeeBefore);

        assertGt(debtSharesAfter + amountSharesReceived, debtSharesBefore);
    }
}
