// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

contract DebtSharesSetup is Setup {
    function _supplyAndBorrow(uint256 amountToBorrow, address user) internal {
        usdc.approve(address(pool), type(uint256).max);
        pool.supplyAndBorrow(address(usdc), amountToBorrow * 5, amountToBorrow, user);
    }

    function _supplyAndBorrow(uint256 amountToBorrow) internal {
        _supplyAndBorrow(amountToBorrow, address(this));
    }

    function _swap(address synthIn, address synthOut, uint256 amountIn, address receiver)
        internal
    {
        xusd.approve(address(exchanger), type(uint256).max);
        exchanger.swap{value: exchanger.getSwapFeeForSettle()}(
            synthIn, synthOut, amountIn, receiver
        );
    }

    function _swap(address synthIn, address synthOut, uint256 amountIn) internal {
        _swap(synthIn, synthOut, amountIn, address(this));
    }
}
