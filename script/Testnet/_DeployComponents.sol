// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Settings} from "./_Settings.sol";
import {Deploy} from "../Deploy/Deploy.sol";
import {FileUtils} from "../../utils/FileHelpers.sol";

import {Provider} from "src/periphery/Provider.sol";
import {Exchanger} from "src/platforms/Synths/Exchanger.sol";
import {DiaOracleAdapter} from "src/periphery/DiaOracleAdapter.sol";
import {Pool} from "src/core/pool/Pool.sol";
import {Synth} from "src/platforms/Synths/Synth.sol";
import {PoolDataProvider} from "src/periphery/PoolDataProvider.sol";
import {SynthDataProvider} from "src/platforms/Synths/SynthDataProvider.sol";
import {DebtShares} from "src/core/shares/DebtShares.sol";
import {DiaOracle} from "src/mock/DiaOracle.sol";
import {CalculationsInitParams} from "src/core/pool/modules/_Calculations.sol";

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
        exchanger = _deployExchanger(owner, address(provider), 50, 50, 100, 3 minutes);

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
        synth = _createSynth(address(synthImplementation), owner, address(provider), name, symbol);

        addressToWrite = address(synth);

        return synth;
    }

    function _deployDiaOracle(string[] memory keys, uint256[] memory prices)
        internal
        BroadcastAndWrite("diaOracle")
        returns (DiaOracle diaOracle)
    {
        diaOracle = new DiaOracle(keys, prices);

        addressToWrite = address(diaOracle);

        return diaOracle;
    }

    function _deployDebtShares(Provider provider, Synth xusd)
        internal
        BroadcastAndWrite("debtShares")
        returns (DebtShares debtShares)
    {
        debtShares = _deployDebtShares(owner, address(provider), "xAssets debt shares", "xDS");

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
            liquidationRatio: 12000,
            liquidationPenaltyPercentagePoint: 500,
            liquidationBonusPercentagePoint: 1000,
            loanFee: 100,
            stabilityFee: 100,
            cooldownPeriod: 3 minutes
        });

        pool = _deployPool(owner, address(provider), wxfi, address(debtShares), params);

        provider.setPool(address(pool));

        pool.setCooldownPeriod(60);

        addressToWrite = address(pool);

        return pool;
    }

    function _deployDiaOracleAdapter(Provider provider, DiaOracle diaOracle)
        internal
        BroadcastAndWrite("oracleAdapter")
        returns (DiaOracleAdapter oracleAdapter)
    {
        oracleAdapter = _deployDiaOracleAdapter(owner, address(provider), address(diaOracle));

        provider.setOracle(address(oracleAdapter));

        addressToWrite = address(oracleAdapter);

        return oracleAdapter;
    }

    function _deployPoolDataProvider(Provider provider)
        internal
        BroadcastAndWrite("poolDataProvider")
        returns (PoolDataProvider poolDataProvider)
    {
        poolDataProvider = _deployPoolDataProvider(owner, address(provider));

        addressToWrite = address(poolDataProvider);

        return poolDataProvider;
    }

    function _deploySynthDataProvider(Provider provider)
        internal
        BroadcastAndWrite("synthDataProvider")
        returns (SynthDataProvider synthDataProvider)
    {
        synthDataProvider = _deploySynthDataProvider(owner, address(provider));

        addressToWrite = address(synthDataProvider);

        return synthDataProvider;
    }

    function _deployXUSD(Provider provider)
        internal
        BroadcastAndWrite("xusd")
        returns (Synth xusd)
    {
        xusd = _deployXUSD(owner, address(provider), "XUSD", "XUSD");

        provider.setXUSD(address(xusd));

        addressToWrite = address(xusd);

        return xusd;
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
