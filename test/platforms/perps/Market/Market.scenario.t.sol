// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract MarketScenario is MarketSetup {
    function _afterSetup() internal override {
        super._afterSetup();

        marketGold.setTakerFee(0);
        marketGold.setMakerFee(0);
        marketGold.setTradeFeeRatio(0);
    }

    function test_ShouldPayFunding() public {
        // address user1 = address(this);
        address user2 = address(0x99009);

        marketGold.transferMargin(int256(amountBorrowed));
        marketGold.modifyPosition(10e18);

        uint256 user2MarginAmountBefore = amountBorrowed / 100 * 90;

        {
            vm.startPrank(user2);
            deal(address(usdc), user2, amountSupplied);
            usdc.approve(address(pool), type(uint256).max);
            pool.supply(address(usdc), amountSupplied);
            pool.borrow(amountBorrowed, type(uint256).max, user2);
            xusd.approve(address(marketGold), type(uint256).max);
            marketGold.transferMargin(int256(user2MarginAmountBefore));
            marketGold.modifyPosition(-1e18);
            vm.stopPrank();
        }

        int256 currentFundingRate = marketGold.currentFundingRate();
        console.log("currentFundingRate", currentFundingRate);

        skip(10 days);

        _updateOraclePrice();

        vm.prank(user2);
        marketGold.modifyPosition(1e18);

        uint256 user2MarginAmountAfter = marketGold.getPerpPosition(user2).margin;

        console.log("user2MarginAmountBefore", user2MarginAmountBefore);
        console.log("user2MarginAmountAfter", user2MarginAmountAfter);

        assertGt(user2MarginAmountAfter, user2MarginAmountBefore);
    }
}
