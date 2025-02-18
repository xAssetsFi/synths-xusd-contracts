// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_DebtShares.Setup.sol";

contract DebtSharesRewarderTest is DebtSharesSetup {
    function testFuzz_claimReward(uint256 amountToBorrow) public {
        vm.assume(amountToBorrow > fuzzingDust);
        vm.assume(amountToBorrow < usdc.balanceOf(address(this)) / 5);

        _supplyAndBorrow(amountToBorrow);
        _swap(address(xusd), address(tesla), amountToBorrow);
        _finishSwap(address(this), address(tesla));

        skip(debtShares.DURATION());

        uint256 earned = debtShares.earned(address(xusd), address(this));

        uint256 balanceBefore = xusd.balanceOf(address(this));

        (address[] memory tokens, uint256[] memory amounts) = debtShares.claimRewards();

        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(xusd));
        assertEq(amounts[0], earned);

        assertEq(xusd.balanceOf(address(this)), balanceBefore + earned);
    }

    function test_earned() public {
        uint256 amountToBorrow = 100 ether;
        assertEq(debtShares.earned(address(xusd), address(this)), 0);

        _supplyAndBorrow(amountToBorrow);
        _swap(address(xusd), address(tesla), amountToBorrow);
        _finishSwap(address(this), address(tesla));

        _skipAndUpdateOraclePrice(10 days);

        uint256 earned = debtShares.earned(address(xusd), address(this));

        assertNotEq(earned, 0);

        _skipAndUpdateOraclePrice(10 days);

        assertEq(debtShares.earned(address(xusd), address(this)), earned);
    }
}
