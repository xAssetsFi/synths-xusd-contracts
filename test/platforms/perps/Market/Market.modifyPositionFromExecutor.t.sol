// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract ModifyPositionFromExecutor is MarketSetup {
    address executor = address(0x9999999);

    function _afterSetup() internal override {
        super._afterSetup();

        marketGold.transferMargin(int256(amountBorrowed));

        marketGold.approveExecutor(executor);
    }

    function test_ShouldModifyPositionSize() public {
        int256 targetPositionSize = 1e18 / 4; // leverage = 1

        assertEq(marketGold.getPerpPosition(address(this)).size, 0);

        vm.startPrank(executor);
        marketGold.modifyPositionFromExecutor(
            address(this),
            targetPositionSize,
            marketGold.fillPrice(targetPositionSize, marketGold.assetPrice())
        );

        assertEq(marketGold.getPerpPosition(address(this)).size, targetPositionSize);
    }

    function test_ShouldRevertIfNotAllowedExecutor() public {
        uint256 fillPrice = marketGold.fillPrice(1e18 / 4, marketGold.assetPrice());

        vm.expectRevert(IMarket.NotAllowedExecutor.selector);
        marketGold.modifyPositionFromExecutor(address(this), 1e18 / 4, fillPrice);
    }
}
