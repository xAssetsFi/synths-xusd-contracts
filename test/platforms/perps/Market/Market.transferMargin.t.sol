// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_Market.Setup.t.sol";

contract TransferMargin is MarketSetup {
    function testFuzz_ShouldDepositMargin(uint256 xusdAmount) public {
        _depositFuzzAssumptions(xusdAmount);

        uint256 addressThisBefore = xusd.balanceOf(address(this));
        marketGold.transferMargin(int256(xusdAmount));
        uint256 addressThisAfter = xusd.balanceOf(address(this));

        assertEq(addressThisAfter, addressThisBefore - xusdAmount);

        assertEq(marketGold.getPerpPosition(address(this)).margin, xusdAmount);
    }

    function testFuzz_ShouldWithdrawMargin(uint256 depositAmount, uint256 withdrawAmount) public {
        _depositFuzzAssumptions(depositAmount);
        marketGold.transferMargin(int256(depositAmount));
        _withdrawFuzzAssumptions(withdrawAmount);

        uint256 addressThisBefore = xusd.balanceOf(address(this));
        marketGold.transferMargin(-int256(withdrawAmount));
        uint256 addressThisAfter = xusd.balanceOf(address(this));

        assertEq(addressThisAfter, addressThisBefore + withdrawAmount);

        assertEq(marketGold.getPerpPosition(address(this)).margin, depositAmount - withdrawAmount);
    }

    function testFuzz_ShouldWithdrawAllMargin(uint256 depositAmount) public {
        _depositFuzzAssumptions(depositAmount);
        marketGold.transferMargin(int256(depositAmount));

        uint256 addressThisBefore = xusd.balanceOf(address(this));
        marketGold.transferMargin(-int256(depositAmount));
        uint256 addressThisAfter = xusd.balanceOf(address(this));

        assertEq(addressThisAfter, addressThisBefore + depositAmount);

        assertEq(marketGold.getPerpPosition(address(this)).margin, 0);
    }
}
