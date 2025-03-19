// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Fork} from "../../utils/Fork.sol";
import {Deploy} from "../Deploy/Deploy.sol";
import {Settings} from "./_Settings.sol";
import {FileUtils} from "../../utils/FileHelpers.sol";
import {DeployComponents} from "./_DeployComponents.sol";

import {Provider} from "src/Provider.sol";
import {Exchanger} from "src/platforms/synths/Exchanger.sol";
import {DiaOracleAdapter} from "src/DiaOracleAdapter.sol";
import {Pool} from "src/Pool.sol";
import {Synth} from "src/platforms/synths/Synth.sol";
import {PoolDataProvider} from "src/misc/PoolDataProvider.sol";
import {SynthDataProvider} from "src/misc/SynthDataProvider.sol";
import {DebtShares} from "src/DebtShares.sol";
import {DiaOracleMock} from "test/mock/DiaOracleMock.sol";
import {MarketManager} from "src/platforms/perps/MarketManager.sol";
import {Market} from "src/platforms/perps/Market.sol";

contract DeployAppTestnet is Script, Fork, Settings, DeployComponents {
    Provider provider;
    Exchanger exchanger;
    Synth xusd;
    Synth synthImplementation;
    DiaOracleMock diaOracle;
    DebtShares debtShares;
    Pool pool;
    DiaOracleAdapter oracleAdapter;
    PoolDataProvider poolDataProvider;
    SynthDataProvider synthDataProvider;

    Market marketImpl;
    MarketManager marketManager;
    Market marketGold;
    Market marketBtc;

    function setUp() public virtual {
        _setupCollateralAndAssets();

        fork(chainId);

        _afterSetup();
    }

    function run() public {
        provider = _deployProvider();
        exchanger = _deployExchanger(provider);
        xusd = _deployXUSD(provider);

        synthImplementation = _deploySynthImpl();
        _createSynths(synthImplementation, provider);

        diaOracle = _deployAndSetupDiaOracle();
        debtShares = _deployDebtShares(provider, xusd);
        pool = _deployPool(provider, debtShares);
        oracleAdapter = _deployDiaOracleAdapter(provider, diaOracle);
        poolDataProvider = _deployPoolDataProvider(provider);
        synthDataProvider = _deploySynthDataProvider(provider);

        _setupOracleAdapter(oracleAdapter);
        _setupCollaterals(pool);

        marketImpl = _deployMarketImpl();
        marketManager = _deployMarketManager(provider);
        marketGold = _deployMarket(provider, address(marketImpl), "xXAU", "XAU", "marketGold");
        marketBtc = _deployMarket(provider, address(marketImpl), "xBTC", "BTC", "marketBtc");

        _afterDeploy();
    }

    function _afterSetup() internal virtual {}

    function _afterDeploy() internal virtual {}

    function _deployAndSetupDiaOracle() internal returns (DiaOracleMock) {
        string[] memory keys = new string[](assets.length + collaterals.length + 1);
        uint128[] memory prices = new uint128[](assets.length + collaterals.length + 1);

        for (uint256 i = 0; i < assets.length; i++) {
            string memory key = string.concat(assets[i].symbol, "/USD");
            keys[i] = key;
            prices[i] = assets[i].price;
        }

        for (uint256 i = 0; i < collaterals.length; i++) {
            string memory key = string.concat(collaterals[i].symbol, "/USD");
            keys[assets.length + i] = key;
            prices[assets.length + i] = collaterals[i].price;
        }

        return _deployDiaOracle(keys, prices);
    }

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

        for (uint256 i = 0; i < markets.length; i++) {
            _oracleAdapter.setKey(
                address(markets[i].tokenAddress), string.concat(markets[i].symbol, "/USD")
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
