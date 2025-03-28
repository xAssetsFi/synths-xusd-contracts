// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {DeploymentSettings} from "./_Settings.sol";
import {Deploy} from "../Deploy/Deploy.sol";
import {FileUtils} from "../../utils/FileHelpers.sol";

import {Provider} from "src/Provider.sol";
import {Exchanger} from "src/platforms/synths/Exchanger.sol";
import {DiaOracleAdapter} from "src/DiaOracleAdapter.sol";
import {Pool} from "src/Pool.sol";
import {Synth} from "src/platforms/synths/Synth.sol";
import {PoolDataProvider} from "src/misc/PoolDataProvider.sol";
import {SynthDataProvider} from "src/misc/SynthDataProvider.sol";
import {DebtShares} from "src/DebtShares.sol";
import {DiaOracleMock} from "test/mock/DiaOracleMock.sol";
import {CalculationsInitParams} from "src/modules/pool/_Calculations.sol";
import {Market} from "src/platforms/perps/Market.sol";
import {MarketManager} from "src/platforms/perps/MarketManager.sol";
import {WETH} from "test/mock/WETH.sol";
import {Multicall3} from "test/mock/Multicall3.sol";

abstract contract Broadcast is Script, Deploy, DeploymentSettings {
    address private addressToWrite;

    function _broadcastDeployProvider()
        internal
        BroadcastAndWrite("provider")
        returns (Provider provider)
    {
        provider = _deployProvider(owner);

        addressToWrite = address(provider);

        return provider;
    }

    function _broadcastDeployExchanger(Provider provider)
        internal
        BroadcastAndWrite("exchanger")
        returns (Exchanger exchanger)
    {
        exchanger = _deployExchanger(
            address(provider),
            exchangerSettings.swapFee,
            exchangerSettings.rewarderFee,
            exchangerSettings.burntAtSwap,
            exchangerSettings.settlementDelay
        );

        provider.setExchanger(address(exchanger));

        addressToWrite = address(exchanger);

        return exchanger;
    }

    function _broadcastDeploySynthImpl()
        internal
        BroadcastAndWrite("synthImpl")
        returns (Synth synthImplementation)
    {
        synthImplementation = new Synth();

        addressToWrite = address(synthImplementation);

        return synthImplementation;
    }

    function _broadcastDeploySynths(
        Provider provider,
        Synth synthImplementation,
        string memory name,
        string memory symbol
    ) internal BroadcastAndWrite(symbol) returns (Synth synth) {
        synth = _createSynth(address(synthImplementation), address(provider), name, symbol);

        addressToWrite = address(synth);

        return synth;
    }

    function _broadcastDeployDiaOracle(string[] memory keys, uint128[] memory prices)
        internal
        BroadcastAndWrite("mockDiaOracle")
        returns (DiaOracleMock _diaOracle)
    {
        _diaOracle = new DiaOracleMock();
        _diaOracle.setValues(keys, prices);

        addressToWrite = address(_diaOracle);

        return _diaOracle;
    }

    function _broadcastDeployDebtShares(Provider provider, Synth xusd)
        internal
        BroadcastAndWrite("debtShares")
        returns (DebtShares debtShares)
    {
        debtShares = _deployDebtShares(address(provider), "xAssets debt shares", "xDS");

        debtShares.addRewardToken(address(xusd));

        addressToWrite = address(debtShares);

        return debtShares;
    }

    function _broadcastDeployPool(Provider provider, DebtShares debtShares)
        internal
        BroadcastAndWrite("pool")
        returns (Pool pool)
    {
        CalculationsInitParams memory params = CalculationsInitParams({
            collateralRatio: poolSettings.collateralRatio,
            liquidationRatio: poolSettings.liquidationRatio,
            liquidationPenaltyPercentagePoint: poolSettings.liquidationPenaltyPercentagePoint,
            liquidationBonusPercentagePoint: poolSettings.liquidationBonusPercentagePoint,
            loanFee: poolSettings.loanFee,
            stabilityFee: poolSettings.stabilityFee,
            cooldownPeriod: poolSettings.cooldownPeriod
        });

        pool = _deployPool(address(provider), wxfi, address(debtShares), params);

        provider.setPool(address(pool));

        addressToWrite = address(pool);

        return pool;
    }

    function _broadcastDeployDiaOracleAdapter(Provider provider, address _diaOracle)
        internal
        BroadcastAndWrite("oracleAdapter")
        returns (DiaOracleAdapter oracleAdapter)
    {
        oracleAdapter = _deployDiaOracleAdapter(address(provider), _diaOracle);

        provider.setOracle(address(oracleAdapter));

        addressToWrite = address(oracleAdapter);

        return oracleAdapter;
    }

    function _broadcastDeployPoolDataProvider(Provider provider)
        internal
        BroadcastAndWrite("poolDataProvider")
        returns (PoolDataProvider poolDataProvider)
    {
        poolDataProvider = _deployPoolDataProvider(address(provider));

        addressToWrite = address(poolDataProvider);

        return poolDataProvider;
    }

    function _broadcastDeploySynthDataProvider(Provider provider)
        internal
        BroadcastAndWrite("synthDataProvider")
        returns (SynthDataProvider synthDataProvider)
    {
        synthDataProvider = _deploySynthDataProvider(address(provider));

        addressToWrite = address(synthDataProvider);

        return synthDataProvider;
    }

    function _broadcastDeployXUSD(Synth synthImplementation, Provider provider)
        internal
        BroadcastAndWrite("xusd")
        returns (Synth xusd)
    {
        xusd = _deployXUSD(address(synthImplementation), address(provider), "XUSD", "XUSD");

        addressToWrite = address(xusd);

        return xusd;
    }

    function _setupOracleAdapter(DiaOracleAdapter _oracleAdapter) internal BroadcastAndWrite("") {
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
    }

    function _setupCollaterals(Pool _pool) internal BroadcastAndWrite("") {
        for (uint256 i = 0; i < collaterals.length; i++) {
            _pool.addCollateralToken(address(collaterals[i].tokenAddress));
        }
    }

    function _broadcastDeployMarketImpl()
        internal
        BroadcastAndWrite("marketImpl")
        returns (Market marketImpl)
    {
        marketImpl = new Market();

        addressToWrite = address(marketImpl);

        return marketImpl;
    }

    function _broadcastDeployMarketManager(Provider provider)
        internal
        BroadcastAndWrite("marketManager")
        returns (MarketManager marketManager)
    {
        marketManager = _deployMarketManager(address(provider));

        addressToWrite = address(marketManager);

        provider.setMarketManager(address(marketManager));

        return marketManager;
    }

    function _broadcastDeployMarket(
        Provider provider,
        address marketImpl,
        bytes32 marketKey,
        bytes32 baseAsset,
        string memory symbol
    ) internal BroadcastAndWrite(string.concat(symbol, "PerpMarket")) returns (Market market) {
        market = _createMarket(address(marketImpl), address(provider), marketKey, baseAsset);

        addressToWrite = address(market);

        return market;
    }

    function _broadcastDeployWxfi() internal BroadcastAndWrite("wxfi") returns (WETH wxfi) {
        wxfi = new WETH("Wrapped XFI", "WXFI");

        addressToWrite = address(wxfi);

        return wxfi;
    }

    function _broadcastDeployMulticall3()
        internal
        BroadcastAndWrite("multicall3")
        returns (Multicall3 multicall3)
    {
        multicall3 = new Multicall3();

        addressToWrite = address(multicall3);

        return multicall3;
    }

    modifier BroadcastAndWrite(string memory _name) {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();

        FileUtils fileUtils = new FileUtils();

        if (bytes(_name).length > 0) {
            fileUtils.writeContractAddress(chainId, addressToWrite, _name);
        }
    }
}
