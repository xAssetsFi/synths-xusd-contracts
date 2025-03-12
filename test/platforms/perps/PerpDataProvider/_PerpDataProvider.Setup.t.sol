// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

contract PerpDataProviderSetup is Setup {
    uint256 amountSupplied = 100000 ether;
    uint256 amountBorrowed = 5000 ether;
    int256 positionSize = 10e18; // long position, leverage = 4

    function _afterSetup() internal override {
        super._afterSetup();

        pool.supply(address(usdc), amountSupplied);
        pool.borrow(amountBorrowed, type(uint256).max, address(this));

        xusd.approve(address(marketGold), type(uint256).max);

        marketGold.transferMargin(int256(amountBorrowed));
        marketGold.modifyPosition(positionSize);
    }
}
