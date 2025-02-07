// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

import {DiaOracleAdapter} from "src/periphery/DiaOracleAdapter.sol";

contract DiaOracleAdapterSetup is Setup {
    function _createFallbackOracle(DiaOracleMock _diaOracle) internal returns (DiaOracleAdapter) {
        DiaOracleAdapter fallbackOracle =
            _deployDiaOracleAdapter(address(this), address(provider), address(_diaOracle));

        _setUpOracleAdapter(fallbackOracle);

        return fallbackOracle;
    }
}
