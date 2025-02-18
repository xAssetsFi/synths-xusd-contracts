// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Pool.Setup.sol";

import {IPool} from "src/interface/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolSupplyTest is PoolSetup {
    function testFuzz_supply_inEmptyPosition(uint256 amount)
        public
        assumeValidSupplyAmount(amount, wxfi)
    {
        uint256 balanceBefore = wxfi.balanceOf(address(this));
        pool.supply(address(wxfi), amount);
        uint256 balanceAfter = wxfi.balanceOf(address(this));

        assertEq(balanceBefore - balanceAfter, amount);
        assertEq(wxfi.balanceOf(address(pool)), amount);

        IPool.Position memory position = pool.getPosition(address(this));
        assertEq(position.collaterals.length, 1);
        assertEq(position.collaterals[0].amount, amount);
        assertEq(position.collaterals[0].token, address(wxfi));
        assertEq(debtShares.balanceOf(address(this)), 0);
    }

    function testFuzz_supply_inNonEmptyPosition_SameAsset(uint256 amount)
        public
        assumeValidSupplyAmount(amount, wxfi)
    {
        vm.assume(amount * 2 <= wxfi.balanceOf(address(this)));

        pool.supply(address(wxfi), amount);
        pool.supply(address(wxfi), amount);

        IPool.Position memory position = pool.getPosition(address(this));
        assertEq(position.collaterals.length, 1);
        assertEq(position.collaterals[0].amount, amount * 2);
        assertEq(position.collaterals[0].token, address(wxfi));
        assertEq(debtShares.balanceOf(address(this)), 0);
    }

    function testFuzz_supply_inNonEmptyPosition_DifferentAsset(uint256 amount)
        public
        assumeValidSupplyAmount(amount, wxfi)
        assumeValidSupplyAmount(amount * 2, wbtc)
    {
        pool.supply(address(wxfi), amount);
        pool.supply(address(wbtc), amount * 2);

        IPool.Position memory position = pool.getPosition(address(this));
        assertEq(position.collaterals.length, 2);
        assertEq(position.collaterals[0].amount, amount);
        assertEq(position.collaterals[0].token, address(wxfi));
        assertEq(position.collaterals[1].amount, amount * 2);
        assertEq(position.collaterals[1].token, address(wbtc));
        assertEq(debtShares.balanceOf(address(this)), 0);
    }

    function testFuzz_supplyAndBorrow(uint256 amount)
        public
        assumeValidSupplyAmount(amount, wxfi)
    {
        uint256 borrowAmount = (amount * WAD) / pool.getMinHealthFactorForBorrow()
            / pool.getCurrentLiquidationRatio() / PRECISION;

        vm.assume(borrowAmount > fuzzingDust);

        uint256 xusdAmountBefore = xusd.balanceOf(address(this));
        uint256 usdcAmountBefore = usdc.balanceOf(address(this));

        pool.supplyAndBorrow(address(usdc), amount, borrowAmount, address(this));

        uint256 xusdAmountAfter = xusd.balanceOf(address(this));
        uint256 usdcAmountAfter = usdc.balanceOf(address(this));

        assertEq(xusdAmountAfter - xusdAmountBefore, borrowAmount);
        assertEq(usdcAmountBefore - usdcAmountAfter, amount);
    }

    function testFuzz_supplyETH(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= address(this).balance);

        uint256 xfiAmountBefore = address(this).balance;

        pool.supplyETH{value: amount}();

        uint256 xfiAmountAfter = address(this).balance;

        IPool.Position memory position = pool.getPosition(address(this));
        assertEq(position.collaterals.length, 1);
        assertEq(position.collaterals[0].amount, amount);
        assertEq(position.collaterals[0].token, address(wxfi));

        assertLt(xfiAmountAfter, xfiAmountBefore);
    }

    function testFuzz_supplyETHAndBorrow(uint256 collateral) public {
        vm.assume(collateral > fuzzingDust);
        vm.assume(collateral <= address(this).balance);

        uint256 borrowAmount = collateral / 4;

        address to = makeAddr("to");

        uint256 xfiAmountBefore = address(this).balance;
        uint256 xusdAmountBefore = xusd.balanceOf(to);
        uint256 debtSharesAmountBefore = debtShares.balanceOf(address(this));

        pool.supplyETHAndBorrow{value: collateral}(borrowAmount, to);

        uint256 xfiAmountAfter = address(this).balance;
        uint256 xusdAmountAfter = xusd.balanceOf(to);
        uint256 debtSharesAmountAfter = debtShares.balanceOf(address(this));

        IPool.Position memory position = pool.getPosition(address(this));
        assertEq(position.collaterals.length, 1);
        assertEq(position.collaterals[0].amount, collateral);
        assertEq(position.collaterals[0].token, address(wxfi));

        uint256 loanFee = 100;
        assertEq(
            xusdAmountAfter - xusdAmountBefore, borrowAmount - (borrowAmount * loanFee) / PRECISION
        );
        assertGt(debtSharesAmountAfter, debtSharesAmountBefore);

        assertLt(xfiAmountAfter, xfiAmountBefore);
    }

    function test_stabilityFeeAccountInSupply() public {
        uint256 borrowedAmount = 100 ether;

        pool.supply(address(wxfi), 1000 ether);
        pool.borrow(borrowedAmount, address(this));

        _skipAndUpdateOraclePrice(1 weeks);

        uint256 stabilityFeeBefore = pool.calculateStabilityFee(address(this));
        uint256 debtSharesBefore = debtShares.balanceOf(address(this));

        pool.supply(address(wxfi), 100 ether);

        uint256 stabilityFeeAfter = pool.calculateStabilityFee(address(this));
        uint256 debtSharesAfter = debtShares.balanceOf(address(this));

        assertEq(stabilityFeeAfter, 0);
        assertLt(stabilityFeeAfter, stabilityFeeBefore);

        assertGt(debtSharesAfter + borrowedAmount, debtSharesBefore);
    }

    function test_stabilityFeeDoNotIncreaseIfZeroDebt() public {
        pool.supply(address(wxfi), 100 ether);
        _skipAndUpdateOraclePrice(1 weeks);

        uint256 stabilityFeeBefore = pool.calculateStabilityFee(address(this));

        pool.supply(address(wxfi), 100 ether);

        uint256 stabilityFeeAfter = pool.calculateStabilityFee(address(this));

        assertEq(stabilityFeeAfter, 0);
        assertEq(stabilityFeeAfter, stabilityFeeBefore);
    }

    modifier assumeValidSupplyAmount(uint256 _amount, IERC20 _token) {
        vm.assume(_amount > 0);
        vm.assume(_amount <= _token.balanceOf(address(this)));
        _;
    }
}
