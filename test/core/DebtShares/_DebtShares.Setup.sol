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
}
