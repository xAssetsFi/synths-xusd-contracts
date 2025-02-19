// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Pool.Setup.sol";

import {IPool} from "src/interface/IPool.sol";

contract PoolWithdrawTest is PoolSetup {
    uint256 amountSuppliedXFI = 1e22;
    uint256 amountSuppliedUSDC = 1e18;

    function _afterSetup() internal override {
        super._afterSetup();
        pool.supply(address(wxfi), amountSuppliedXFI);
        pool.supply(address(usdc), amountSuppliedUSDC);
    }

    function testFuzz_withdraw_withNoBorrow(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < amountSuppliedXFI);

        uint256 balanceBefore = wxfi.balanceOf(address(this));
        pool.withdraw(address(wxfi), amount, address(this));
        uint256 balanceAfter = wxfi.balanceOf(address(this));

        assertEq(balanceAfter - balanceBefore, amount);
    }

    function test_withdraw_withNoBorrow_wholeAmountInOneCollateral() public {
        uint256 balanceBefore = wxfi.balanceOf(address(this));
        pool.withdraw(address(wxfi), amountSuppliedXFI, address(this));
        uint256 balanceAfter = wxfi.balanceOf(address(this));

        assertEq(balanceAfter - balanceBefore, amountSuppliedXFI);

        IPool.Position memory position = pool.getPosition(address(this));
        assertEq(position.collaterals.length, 1);
        assertEq(position.collaterals[0].token, address(usdc));
    }

    function test_withdraw_withNoBorrow_closePosition() public {
        pool.withdraw(address(usdc), amountSuppliedUSDC, address(this));
        pool.withdraw(address(wxfi), amountSuppliedXFI, address(this));

        vm.expectRevert();
        pool.getPosition(address(this));
    }

    function testFuzz_withdraw_withBorrow(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= amountSuppliedUSDC);
        pool.setStabilityFee(0);

        pool.borrow(1e18, address(this));

        uint256 healthFactorBefore = pool.getHealthFactor(address(this));
        uint256 balanceBefore = usdc.balanceOf(address(this));
        pool.withdraw(address(usdc), amount, address(this));
        uint256 healthFactorAfter = pool.getHealthFactor(address(this));
        uint256 balanceAfter = usdc.balanceOf(address(this));

        assertGt(healthFactorBefore, healthFactorAfter);
        assertEq(balanceAfter - balanceBefore, amount);
    }

    function test_withdraw_withBorrow_wholeAmountInOneCollateral() public {
        pool.borrow(1e18, address(this));

        pool.withdraw(address(usdc), amountSuppliedUSDC, address(this));

        IPool.Position memory position = pool.getPosition(address(this));
        assertEq(position.collaterals.length, 1);
        assertEq(position.collaterals[0].token, address(wxfi));
    }

    function testFuzz_withdrawETH(uint256 amount) public {
        vm.assume(amount > fuzzingDust);
        vm.assume(amount <= address(this).balance);

        address to = makeAddr("to");

        pool.supplyETH{value: amount}();

        pool.withdrawETH(amount, to);

        assertEq(to.balance, amount);
    }

    function test_stabilityFeeAccountInWithdraw() public {
        pool.borrow(1e18, address(this));

        _skipAndUpdateOraclePrice(1 weeks);

        uint256 stabilityFeeBefore = pool.calculateStabilityFee(address(this));
        uint256 debtSharesBefore = debtShares.balanceOf(address(this));

        pool.withdraw(address(wxfi), amountSuppliedXFI, address(this));

        uint256 stabilityFeeAfter = pool.calculateStabilityFee(address(this));
        uint256 debtSharesAfter = debtShares.balanceOf(address(this));

        assertEq(stabilityFeeAfter, 0);
        assertLt(stabilityFeeAfter, stabilityFeeBefore);

        assertGt(debtSharesAfter + amountSuppliedXFI, debtSharesBefore);
    }
}
