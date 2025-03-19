// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Settings} from "./_Settings.sol";
import {Deploy} from "../Deploy/Deploy.sol";
import {FileUtils} from "../../utils/FileHelpers.sol";

import {Provider} from "src/Provider.sol";
import {Exchanger} from "src/platforms/synths/Exchanger.sol";
import {DiaOracleAdapter} from "src/DiaOracleAdapter.sol";
import {Pool} from "src/Pool.sol";
import {Synth} from "src/platforms/synths/Synth.sol";
import {MarketManager} from "src/platforms/perps/MarketManager.sol";
import {Market} from "src/platforms/perps/Market.sol";
import {PoolDataProvider} from "src/misc/PoolDataProvider.sol";
import {SynthDataProvider} from "src/misc/SynthDataProvider.sol";
import {DebtShares} from "src/DebtShares.sol";
import {DiaOracleMock} from "test/mock/DiaOracleMock.sol";
import {CalculationsInitParams} from "src/modules/pool/_Calculations.sol";

contract DeployComponents is Script, Deploy, Settings {
    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    address private addressToWrite;

    uint32 chainId = 4157;

    function _deployProvider() internal BroadcastAndWrite("provider") returns (Provider provider) {
        provider = _deployProvider(owner);

        addressToWrite = address(provider);

        return provider;
    }

    function _deployExchanger(Provider provider)
        internal
        BroadcastAndWrite("exchanger")
        returns (Exchanger exchanger)
    {
        exchanger = _deployExchanger(address(provider), 50, 50, 100, 3 minutes);

        provider.setExchanger(address(exchanger));

        addressToWrite = address(exchanger);

        return exchanger;
    }

    function _deploySynthImpl()
        internal
        BroadcastAndWrite("synthImpl")
        returns (Synth synthImplementation)
    {
        synthImplementation = new Synth();

        addressToWrite = address(synthImplementation);

        return synthImplementation;
    }

    function _deploySynths(
        Provider provider,
        Synth synthImplementation,
        string memory name,
        string memory symbol
    ) internal BroadcastAndWrite(symbol) returns (Synth synth) {
        synth = _createSynth(address(synthImplementation), address(provider), name, symbol);

        addressToWrite = address(synth);

        return synth;
    }

    function _deployDiaOracle(string[] memory keys, uint128[] memory prices)
        internal
        BroadcastAndWrite("diaOracle")
        returns (DiaOracleMock diaOracle)
    {
        diaOracle = new DiaOracleMock();

        diaOracle.setValues(keys, prices);

        addressToWrite = address(diaOracle);

        return diaOracle;
    }

    function _deployDebtShares(Provider provider, Synth xusd)
        internal
        BroadcastAndWrite("debtShares")
        returns (DebtShares debtShares)
    {
        debtShares = _deployDebtShares(address(provider), "xAssets debt shares", "xDS");

        debtShares.addRewardToken(address(xusd));

        addressToWrite = address(debtShares);

        return debtShares;
    }

    function _deployPool(Provider provider, DebtShares debtShares)
        internal
        BroadcastAndWrite("pool")
        returns (Pool pool)
    {
        CalculationsInitParams memory params = CalculationsInitParams({
            collateralRatio: 30000,
            liquidationRatio: 15000,
            liquidationPenaltyPercentagePoint: 500,
            liquidationBonusPercentagePoint: 500,
            loanFee: 100,
            stabilityFee: 100,
            cooldownPeriod: 3 minutes
        });

        pool = _deployPool(address(provider), wxfi, address(debtShares), params);

        provider.setPool(address(pool));

        pool.setCooldownPeriod(60);

        addressToWrite = address(pool);

        return pool;
    }

    function _deployDiaOracleAdapter(Provider provider, DiaOracleMock diaOracle)
        internal
        BroadcastAndWrite("oracleAdapter")
        returns (DiaOracleAdapter oracleAdapter)
    {
        oracleAdapter = _deployDiaOracleAdapter(address(provider), address(diaOracle));

        provider.setOracle(address(oracleAdapter));

        addressToWrite = address(oracleAdapter);

        return oracleAdapter;
    }

    function _deployPoolDataProvider(Provider provider)
        internal
        BroadcastAndWrite("poolDataProvider")
        returns (PoolDataProvider poolDataProvider)
    {
        poolDataProvider = _deployPoolDataProvider(address(provider));

        addressToWrite = address(poolDataProvider);

        return poolDataProvider;
    }

    function _deploySynthDataProvider(Provider provider)
        internal
        BroadcastAndWrite("synthDataProvider")
        returns (SynthDataProvider synthDataProvider)
    {
        synthDataProvider = _deploySynthDataProvider(address(provider));

        addressToWrite = address(synthDataProvider);

        return synthDataProvider;
    }

    function _deployXUSD(Provider provider)
        internal
        BroadcastAndWrite("xusd")
        returns (Synth xusd)
    {
        xusd = _deployXUSD(address(provider), "XUSD", "XUSD");

        provider.setXUSD(address(xusd));

        addressToWrite = address(xusd);

        return xusd;
    }

    function _deployMarketManager(Provider provider)
        internal
        BroadcastAndWrite("marketManager")
        returns (MarketManager marketManager)
    {
        marketManager = _deployMarketManager(address(provider));

        provider.setMarketManager(address(marketManager));

        addressToWrite = address(marketManager);

        return marketManager;
    }

    function _deployMarketImpl() internal BroadcastAndWrite("marketImpl") returns (Market market) {
        market = new Market();

        addressToWrite = address(market);

        return market;
    }

    function _deployMarket(
        Provider provider,
        address marketImpl,
        bytes32 marketKey,
        bytes32 baseAsset,
        string memory marketKeyString
    ) internal BroadcastAndWrite(marketKeyString) returns (Market market) {
        market = _createMarket(marketImpl, address(provider), marketKey, baseAsset);

        addressToWrite = address(market);

        return market;
    }

    modifier BroadcastAndWrite(string memory _name) {
        vm.startBroadcast(privateKey);
        _;
        vm.stopBroadcast();

        FileUtils fileUtils = new FileUtils();

        //TODO: remove hardcoded chain id

        fileUtils.writeContractAddress(chainId, addressToWrite, _name);
    }
}
