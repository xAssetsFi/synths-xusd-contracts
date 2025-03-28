// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {Fork} from "../../utils/Fork.sol";
import {DeploymentSettings} from "./_Settings.sol";
import {Broadcast} from "./_Broadcast.sol";

import {Provider} from "src/Provider.sol";
import {Exchanger} from "src/platforms/synths/Exchanger.sol";
import {DiaOracleAdapter} from "src/DiaOracleAdapter.sol";
import {Pool} from "src/Pool.sol";
import {Synth} from "src/platforms/synths/Synth.sol";
import {PoolDataProvider} from "src/misc/PoolDataProvider.sol";
import {SynthDataProvider} from "src/misc/SynthDataProvider.sol";
import {DebtShares} from "src/DebtShares.sol";
import {DiaOracleMock} from "test/mock/DiaOracleMock.sol";
import {Market} from "src/platforms/perps/Market.sol";
import {MarketManager} from "src/platforms/perps/MarketManager.sol";

abstract contract DeployApp is Script, Fork, DeploymentSettings, Broadcast {
    /* ======== CORE ======== */

    Provider provider;
    Synth synthImplementation;
    Synth xusd;
    DebtShares debtShares;
    Pool pool;
    DiaOracleAdapter oracleAdapter;
    PoolDataProvider poolDataProvider;

    /* ======== SYNTH PLATFORM ======== */

    Exchanger exchanger;
    SynthDataProvider synthDataProvider;

    /* ======== PERPS ======== */

    Market marketImpl;
    MarketManager marketManager;

    constructor(Settings memory settings) DeploymentSettings(settings) {}

    function setUp() public virtual {
        fork(chainId);

        _afterSetup();
    }

    function run() public deployDiaOracleIfNeeded {
        _deployCore();

        _deploySynthPlatform();

        oracleAdapter = _deployAndSetupOracleAdapter();

        _deployPerps();

        _afterDeploy();
    }

    /* ======== DEPLOY CORE ======== */

    function _deployCore() internal {
        provider = _broadcastDeployProvider();

        synthImplementation = _broadcastDeploySynthImpl();

        xusd = _broadcastDeployXUSD(synthImplementation, provider);
        debtShares = _broadcastDeployDebtShares(provider, xusd);
        pool = _broadcastDeployPool(provider, debtShares);

        poolDataProvider = _broadcastDeployPoolDataProvider(provider);
    }

    function _deployAndSetupOracleAdapter() internal returns (DiaOracleAdapter) {
        DiaOracleAdapter _oracleAdapter = _broadcastDeployDiaOracleAdapter(provider, diaOracle);

        _setupOracleAdapter(_oracleAdapter);

        return _oracleAdapter;
    }

    function _deployPoolAndSetupCollaterals() internal returns (Pool) {
        Pool _pool = _broadcastDeployPool(provider, debtShares);

        _setupCollaterals(_pool);

        return _pool;
    }

    /* ======== DEPLOY SYNTH PLATFORM ======== */

    function _deploySynthPlatform() internal {
        exchanger = _broadcastDeployExchanger(provider);

        _createSynths(synthImplementation, provider);

        synthDataProvider = _broadcastDeploySynthDataProvider(provider);
    }

    function _createSynths(Synth _synthImplementation, Provider _provider) internal {
        for (uint256 i = 0; i < assets.length; i++) {
            string memory symbol = string.concat("x", assets[i].symbol);
            string memory name = string.concat("Synthetic ", assets[i].name);

            Synth synth = _broadcastDeploySynths(_provider, _synthImplementation, name, symbol);

            assets[i].tokenAddress = address(synth);
        }
    }

    function _deployPerps() internal {
        marketImpl = _broadcastDeployMarketImpl();
        marketManager = _broadcastDeployMarketManager(provider);

        _createMarkets();
    }

    function _createMarkets() internal {
        for (uint256 i = 0; i < assets.length; i++) {
            bytes32 marketKey = bytes32(uint256(i + 1));
            bytes32 baseAsset = bytes32(uint256(uint160(assets[i].tokenAddress)));
            string memory symbol = assets[i].symbol;

            Market market =
                _broadcastDeployMarket(provider, address(marketImpl), marketKey, baseAsset, symbol);
        }
    }

    /* ======== DIA ORACLE HANDLING ======== */

    modifier deployDiaOracleIfNeeded() {
        if (diaOracle == address(0)) {
            diaOracle = address(_deployAndSetupDiaOracle());
        }
        _;
    }

    function _deployAndSetupDiaOracle() internal returns (DiaOracleMock) {
        string[] memory keys = new string[](assets.length + collaterals.length + 1);
        uint128[] memory prices = new uint128[](assets.length + collaterals.length + 1);

        for (uint256 i = 0; i < assets.length; i++) {
            string memory key = string.concat(assets[i].symbol, "/USD");
            keys[i] = key;
            prices[i] = uint128(assets[i].price);
        }

        for (uint256 i = 0; i < collaterals.length; i++) {
            string memory key = string.concat(collaterals[i].symbol, "/USD");
            keys[assets.length + i] = key;
            prices[assets.length + i] = uint128(collaterals[i].price);
        }

        return _broadcastDeployDiaOracle(keys, prices);
    }

    /* ======== AFTERS FOR OVERRIDE ======== */

    function _afterSetup() internal virtual {}

    function _afterDeploy() internal virtual {}
}
