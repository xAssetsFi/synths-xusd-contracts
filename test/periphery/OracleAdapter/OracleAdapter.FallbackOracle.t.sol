// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./_OracleAdapter.Setup.sol";

contract DiaOracleAdapterFallbackOracleTest is DiaOracleAdapterSetup {
    function test_getPrice_returnsPriceFromFallbackOracle() public {
        DiaOracleMock _diaOracle = new DiaOracleMock();
        _updateOraclePrice(_diaOracle);
        DiaOracleAdapter fallbackOracle = _createFallbackOracle(_diaOracle);

        diaOracle.setValue("WBTC/USD", 0, uint128(block.timestamp));
        _diaOracle.setValue("WBTC/USD", 1, uint128(block.timestamp));

        oracleAdapter.setFallbackOracle(address(fallbackOracle));

        uint256 price = oracleAdapter.getPrice(address(wbtc));
        assertEq(price, 1);
    }
}
