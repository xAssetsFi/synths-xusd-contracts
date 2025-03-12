// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

import "src/interface/platforms/perps/IMarket.sol";

import "src/lib/SignedSafeMath.sol";

contract MarketSetup is Setup {
    using SignedSafeMath for int256;

    address feeReceiver = address(0x99999);

    uint256 amountSupplied = 100000 ether;
    uint256 amountBorrowed = 5000 ether;

    function _afterSetup() internal virtual override {
        super._afterSetup();

        pool.supply(address(usdc), amountSupplied);
        pool.borrow(amountBorrowed, type(uint256).max, address(this));

        xusd.approve(address(marketGold), type(uint256).max);
    }

    function _depositFuzzAssumptions(uint256 xusdAmount) internal view {
        vm.assume(xusdAmount > 0);
        vm.assume(xusdAmount <= amountBorrowed);
    }

    function _withdrawFuzzAssumptions(uint256 xusdAmount) internal view {
        vm.assume(xusdAmount > 0);
        vm.assume(xusdAmount <= marketGold.getPerpPosition(address(this)).margin);
    }

    function _setGoldPrice(uint256 price) internal {
        diaOracle.setValue("XAU/USD", uint128(price));
    }
}
