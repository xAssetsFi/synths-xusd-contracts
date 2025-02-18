// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_DebtShares.Setup.sol";

contract DebtSharesRewarderMathTest is DebtSharesSetup {
    function _afterSetup() internal override {
        super._afterSetup();
        exchanger.setFinishSwapDelay(0);
        exchanger.setSwapFee(0);
        exchanger.setBurntAtSwap(0);
        exchanger.setRewarderFee(PRECISION / 2);
    }

    function testFuzz_earned_ShouldUnlockAllAmountAfterDuration(uint256 period) public {
        vm.assume(period >= debtShares.DURATION());
        vm.assume(period < 52 weeks * 100);

        uint256 amountXUSD = 100 ether;
        _supplyAndBorrow(amountXUSD);
        _swap(address(xusd), address(tesla), amountXUSD);
        _finishSwap(address(this), address(tesla));

        skip(period);

        uint256 earned = debtShares.earned(address(xusd), address(this));
        assertApproxEqAbs(earned, amountXUSD / 2, 1e6);
    }

    function testFuzz_earned_differentPeriods_oneUser(uint256 period) public {
        vm.assume(period <= debtShares.DURATION());
        // vm.assume(period > fuzzingDust);

        uint256 amountXUSD = 100 ether;
        _supplyAndBorrow(amountXUSD);
        _swap(address(xusd), address(tesla), amountXUSD);
        _finishSwap(address(this), address(tesla));

        skip(period);

        uint256 earned = debtShares.earned(address(xusd), address(this));
        assertApproxEqAbs(earned, ((amountXUSD / 2) * period) / debtShares.DURATION(), 1e6);
    }

    function test_earned_twoUsers_sameStart() public {
        uint256 duration = debtShares.DURATION();

        uint256 amountXUSD = 100 ether;
        uint256 swapAmount = 50 ether;

        _supplyAndBorrow(amountXUSD);
        _swap(address(xusd), address(tesla), swapAmount);
        _finishSwap(address(this), address(tesla));

        vm.startPrank(user);
        _supplyAndBorrow(amountXUSD, user);
        ERC20Token(address(xusd)).approve(address(exchanger), type(uint256).max);
        exchanger.swap{value: exchanger.getFinishSwapFee()}(
            address(xusd), address(tesla), swapAmount, 0, user
        );
        _finishSwap(user, address(tesla));

        skip(duration);

        uint256 earnedThis = debtShares.earned(address(xusd), address(this));
        uint256 earnedUser = debtShares.earned(address(xusd), user);
        assertApproxEqAbs(earnedThis, swapAmount / 2, 1e6);
        assertApproxEqAbs(earnedUser, swapAmount / 2, 1e6);
    }

    function test_earned_twoUsers_differentStart() public {
        uint256 duration = debtShares.DURATION();

        uint256 amountXUSDBeforeFee = 100 ether;
        uint256 swapAmount = 50 ether;

        _supplyAndBorrow(amountXUSDBeforeFee);
        _swap(address(xusd), address(tesla), swapAmount);
        _finishSwap(address(this), address(tesla));

        assertEq(xusd.balanceOf(address(debtShares)), swapAmount / 2);

        skip(duration / 2);

        uint256 earnedThis = debtShares.earned(address(xusd), address(this));
        uint256 earnedUser = debtShares.earned(address(xusd), user);

        /*
            this swaps 50
            rewarder fee is 50%
            passed half of duration
            earned is 1/4 of swap amount
        */
        assertApproxEqAbs(earnedThis, swapAmount / 4, 1e6);
        assertEq(earnedUser, 0);

        vm.startPrank(user);
        _supplyAndBorrow(amountXUSDBeforeFee, user);
        ERC20Token(address(xusd)).approve(address(exchanger), type(uint256).max);
        exchanger.swap{value: exchanger.getFinishSwapFee()}(
            address(xusd), address(tesla), swapAmount, 0, user
        );
        _finishSwap(user, address(tesla));

        skip(duration);

        earnedThis = debtShares.earned(address(xusd), address(this));
        earnedUser = debtShares.earned(address(xusd), user);
        /*
            this swaps 50
            after half of duration user swaps 50
            one duration passed

            this earned:
            1) 1/2 of first swap
            2) half of 1/2 of first swap
            3) 1/2 of second swap
            total: 1/2 + 1/4 + 1/2 = 1.25

            user earned:
            1) half of 1/2 of first swap
            2) 1/2 of second swap
            total: 1/4 + 1/2 = 0.75
        */
        assertApproxEqAbs(earnedThis + earnedUser, xusd.balanceOf(address(debtShares)), 1e8);
        assertGt(xusd.balanceOf(address(debtShares)), earnedThis + earnedUser);
        assertApproxEqAbs(earnedThis + earnedUser, swapAmount, 1e8);
        assertApproxEqAbs(earnedThis, swapAmount / 2 + swapAmount / 8, 1e8);
        assertApproxEqAbs(earnedUser, swapAmount / 8 + swapAmount / 4, 1e8);
    }
}
