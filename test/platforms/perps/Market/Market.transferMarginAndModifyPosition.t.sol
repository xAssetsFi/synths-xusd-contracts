// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract TransferMarginAndModifyPosition is MarketSetup {
    function test_ShouldDepositMarginAndModifyPosition() public {
        int256 targetPositionSize = 1e18 / 4; // leverage = 1

        marketGold.setFeeReceiver(address(0xdead));

        uint256 assetPriceBefore = marketGold.assetPrice();

        uint256 addressThisBefore = xusd.balanceOf(address(this));
        marketGold.transferMarginAndModifyPosition(
            int256(amountBorrowed),
            targetPositionSize,
            marketGold.fillPrice(targetPositionSize, assetPriceBefore)
        );
        uint256 addressThisAfter = xusd.balanceOf(address(this));

        assertEq(addressThisAfter, addressThisBefore - amountBorrowed);

        assertApproxEqAbs(marketGold.getPerpPosition(address(this)).margin, amountBorrowed, 1e19);
        assertEq(marketGold.getPerpPosition(address(this)).size, targetPositionSize);
    }
}
