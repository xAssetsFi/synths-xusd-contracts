// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IProvider} from "src/interface/IProvider.sol";
import {IExchanger} from "src/interface/platforms/synths/IExchanger.sol";

import {Pool} from "src/Pool.sol";
import {DebtShares} from "src/DebtShares.sol";
import {CalculationsInitParams} from "src/modules/pool/_Calculations.sol";

import {Synth} from "src/platforms/synths/Synth.sol";
import {Exchanger} from "src/platforms/synths/Exchanger.sol";
import {SynthDataProvider} from "src/misc/SynthDataProvider.sol";

import {Provider} from "src/Provider.sol";
import {DiaOracleAdapter} from "src/DiaOracleAdapter.sol";
import {PoolDataProvider} from "src/misc/PoolDataProvider.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy {
    function _deployProvider(address _owner) internal returns (Provider) {
        Provider providerImplementation = new Provider();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(providerImplementation),
            abi.encodeWithSelector(providerImplementation.initialize.selector, _owner)
        );

        return Provider(address(proxy));
    }

    function _deployXUSD(address _provider, string memory _name, string memory _symbol)
        internal
        returns (Synth)
    {
        Synth synthImplementation = new Synth();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(synthImplementation),
            abi.encodeWithSelector(
                synthImplementation.initialize.selector, _provider, _name, _symbol
            )
        );

        IProvider(_provider).setXUSD(address(proxy));
        IExchanger(IProvider(_provider).exchanger()).addNewSynth(address(proxy));

        return Synth(address(proxy));
    }

    function _createSynth(
        address _implementation,
        address _provider,
        string memory _name,
        string memory _symbol
    ) internal returns (Synth) {
        address newSynth =
            Provider(_provider).exchanger().createSynth(_implementation, _name, _symbol);

        return Synth(newSynth);
    }

    function _deployPool(
        address _provider,
        address _weth,
        address _debtShares,
        CalculationsInitParams memory params
    ) internal returns (Pool) {
        Pool poolImplementation = new Pool();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(poolImplementation),
            abi.encodeWithSelector(
                poolImplementation.initialize.selector, _provider, _weth, _debtShares, params
            )
        );

        return Pool(payable(address(proxy)));
    }

    function _deployDebtShares(address _provider, string memory _name, string memory _symbol)
        internal
        returns (DebtShares)
    {
        DebtShares debtSharesImplementation = new DebtShares();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(debtSharesImplementation),
            abi.encodeWithSelector(
                debtSharesImplementation.initialize.selector, _provider, _name, _symbol
            )
        );

        return DebtShares(address(proxy));
    }

    function _deployDiaOracleAdapter(address _provider, address _diaOracle)
        internal
        returns (DiaOracleAdapter)
    {
        DiaOracleAdapter diaOracleAdapterImplementation = new DiaOracleAdapter();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(diaOracleAdapterImplementation),
            abi.encodeWithSelector(
                diaOracleAdapterImplementation.initialize.selector, _provider, _diaOracle
            )
        );

        return DiaOracleAdapter(address(proxy));
    }

    function _deployPoolDataProvider(address _provider) internal returns (PoolDataProvider) {
        PoolDataProvider poolDataProviderImplementation = new PoolDataProvider();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(poolDataProviderImplementation),
            abi.encodeWithSelector(poolDataProviderImplementation.initialize.selector, _provider)
        );

        return PoolDataProvider(address(proxy));
    }

    function _deployExchanger(
        address _provider,
        uint256 _swapFee,
        uint256 _rewarderFee,
        uint256 _burntAtSwap,
        uint256 _finishSwapDelay
    ) internal returns (Exchanger) {
        Exchanger exchangerImplementation = new Exchanger();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(exchangerImplementation),
            abi.encodeWithSelector(
                exchangerImplementation.initialize.selector,
                _provider,
                _swapFee,
                _rewarderFee,
                _burntAtSwap,
                _finishSwapDelay
            )
        );

        return Exchanger(address(proxy));
    }

    function _deploySynthDataProvider(address _provider) internal returns (SynthDataProvider) {
        SynthDataProvider synthDataProviderImplementation = new SynthDataProvider();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(synthDataProviderImplementation),
            abi.encodeWithSelector(synthDataProviderImplementation.initialize.selector, _provider)
        );

        return SynthDataProvider(address(proxy));
    }

    function _deployERC1967Proxy(address _implementation, bytes memory _data)
        internal
        returns (ERC1967Proxy)
    {
        return new ERC1967Proxy(_implementation, _data);
    }
}
