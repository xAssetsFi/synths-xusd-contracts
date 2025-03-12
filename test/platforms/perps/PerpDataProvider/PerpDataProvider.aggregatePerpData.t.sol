// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_PerpDataProvider.Setup.t.sol";

contract AggregatePerpData is PerpDataProviderSetup {
    function test_shouldReturnDataWithPositionInfo() public view {
        PerpDataProvider.AggregatedPerpData memory data =
            perpDataProvider.aggregatePerpData(address(this));

        assertEq(data.marketData.length, 1);

        assertEq(data.marketData[0].market, address(marketGold));
        assertNotEq(data.marketData[0].asset, bytes32(0));
        assertNotEq(data.marketData[0].key, bytes32(0));
        assertNotEq(data.marketData[0].price, 0);

        assertNotEq(data.marketData[0].positionData.position.size, 0);
        assertNotEq(data.marketData[0].positionData.position.margin, 0);
        assertNotEq(data.marketData[0].positionData.position.lastPrice, 0);
        assertNotEq(data.marketData[0].positionData.position.lastFundingIndex, 0);
    }
}
