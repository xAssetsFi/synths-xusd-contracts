// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Fork} from "../../utils/Fork.sol";
import {Deploy} from "../Deploy/Deploy.sol";
import {DeploymentSettings} from "./_Settings.sol";
import {FileUtils} from "../../utils/FileHelpers.sol";
import {DeployComponents} from "./_DeployComponents.sol";

import {Provider} from "src/periphery/Provider.sol";
import {Exchanger} from "src/platforms/Synths/Exchanger.sol";
import {DiaOracleAdapter} from "src/periphery/DiaOracleAdapter.sol";
import {Pool} from "src/core/pool/Pool.sol";
import {Synth} from "src/platforms/Synths/Synth.sol";
import {PoolDataProvider} from "src/periphery/PoolDataProvider.sol";
import {SynthDataProvider} from "src/platforms/Synths/SynthDataProvider.sol";
import {DebtShares} from "src/core/shares/DebtShares.sol";

abstract contract DeployApp is Script, Fork, DeploymentSettings, DeployComponents {
    Provider provider;
    Exchanger exchanger;
    Synth xusd;
    Synth synthImplementation;
    address _diaOracle;
    DebtShares debtShares;
    Pool pool;
    DiaOracleAdapter oracleAdapter;
    PoolDataProvider poolDataProvider;
    SynthDataProvider synthDataProvider;

    constructor(Settings memory settings) DeploymentSettings(settings) {}

    function setUp() public virtual {
        fork(chainId);

        _afterSetup();
    }

    function run() public {
        provider = _deployProvider();
        exchanger = _deployExchanger(provider);
        xusd = _deployXUSD(provider);

        synthImplementation = _deploySynthImpl();
        _createSynths(synthImplementation, provider);

        diaOracle = _getDiaOracle();
        debtShares = _deployDebtShares(provider, xusd);
        pool = _deployPool(provider, debtShares);
        oracleAdapter = _deployDiaOracleAdapter(provider, diaOracle);
        poolDataProvider = _deployPoolDataProvider(provider);
        synthDataProvider = _deploySynthDataProvider(provider);

        _setupOracleAdapter(oracleAdapter);
        _setupCollaterals(pool);

        _afterDeploy();
    }

    function _afterSetup() internal virtual {}

    function _afterDeploy() internal virtual {}

    /// @dev override this function to deploy and setup DiaOracle
    function _getDiaOracle() internal virtual returns (address) {
        return address(diaOracle);
    }
    // function _deployAndSetupDiaOracle() internal returns (DiaOracle) {
    //     string[] memory keys = new string[](
    //         assets.length + collaterals.length + 1
    //     );
    //     uint256[] memory prices = new uint256[](
    //         assets.length + collaterals.length + 1
    //     );

    //     for (uint256 i = 0; i < assets.length; i++) {
    //         string memory key = string.concat(assets[i].symbol, "/USD");
    //         keys[i] = key;
    //         prices[i] = assets[i].price;
    //     }

    //     for (uint256 i = 0; i < collaterals.length; i++) {
    //         string memory key = string.concat(collaterals[i].symbol, "/USD");
    //         keys[assets.length + i] = key;
    //         prices[assets.length + i] = collaterals[i].price;
    //     }

    //     return _deployDiaOracle(keys, prices);
    // }

    function _setupOracleAdapter(DiaOracleAdapter _oracleAdapter) internal {
        vm.startBroadcast(privateKey);
        for (uint256 i = 0; i < assets.length; i++) {
            _oracleAdapter.setKey(
                address(assets[i].tokenAddress), string.concat(assets[i].symbol, "/USD")
            );
        }

        for (uint256 i = 0; i < collaterals.length; i++) {
            _oracleAdapter.setKey(
                address(collaterals[i].tokenAddress), string.concat(collaterals[i].symbol, "/USD")
            );
        }
        vm.stopBroadcast();
    }

    function _setupCollaterals(Pool _pool) internal {
        vm.startBroadcast(privateKey);
        for (uint256 i = 0; i < collaterals.length; i++) {
            _pool.addCollateralToken(address(collaterals[i].tokenAddress));
        }
        vm.stopBroadcast();
    }

    function _createSynths(Synth _synthImplementation, Provider _provider) internal {
        for (uint256 i = 0; i < assets.length; i++) {
            string memory symbol = string.concat("x", assets[i].symbol);
            string memory name = string.concat("Synthetic ", assets[i].name);

            Synth synth = _deploySynths(_provider, _synthImplementation, name, symbol);

            assets[i].tokenAddress = address(synth);
        }
    }
}
