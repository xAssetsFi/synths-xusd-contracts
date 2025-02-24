// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_SynthDataProvider.Setup.sol";

contract SynthDataProviderTest is SynthDataProviderSetup {
    function test_synthData() public view {
        ISynthDataProvider.SynthData[] memory data = synthDataProvider.synthsData(address(this));

        assertEq(data.length, 3);
    }

    function test_aggregateSynthData() public view {
        ISynthDataProvider.AggregateSynthData memory data =
            synthDataProvider.aggregateSynthData(address(this));

        assertEq(data.synthsData.length, 3);
        assertEq(data.swapFeeForSettle, exchanger.getFinishSwapFee());
        assertEq(data.settleGasCost, exchanger.finishSwapGasCost());
        assertEq(data.baseFee, block.basefee);
        assertEq(data.settlementDelay, exchanger.finishSwapDelay());
        assertEq(data.burntAtSwap, exchanger.burntAtSwap());
        assertEq(data.rewarderFee, exchanger.rewarderFee());
        assertEq(data.swapFee, exchanger.swapFee());
        assertEq(data.precision, PRECISION);
        assertEq(data.oraclePrecision, oracleAdapter.precision());
    }
}
