// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IProvider} from "src/interface/IProvider.sol";
import {IExchanger} from "src/interface/platforms/synths/IExchanger.sol";

import {Pool} from "src/core/pool/Pool.sol";
import {DebtShares} from "src/core/shares/DebtShares.sol";
import {CalculationsInitParams} from "src/core/pool/modules/_Calculations.sol";

import {Synth} from "src/platforms/Synths/Synth.sol";
import {Exchanger} from "src/platforms/Synths/Exchanger.sol";
import {SynthDataProvider} from "src/platforms/Synths/SynthDataProvider.sol";

import {Provider} from "src/periphery/Provider.sol";
import {DiaOracleAdapter} from "src/periphery/DiaOracleAdapter.sol";
import {PoolDataProvider} from "src/periphery/PoolDataProvider.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy {
    string baseInitializeSignature = "initialize(address,address)";

    function _deployProvider(address _owner) internal returns (Provider) {
        Provider providerImplementation = new Provider();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(providerImplementation),
            abi.encodeWithSelector(providerImplementation.initialize.selector, _owner)
        );

        return Provider(address(proxy));
    }

    function _deployXUSD(
        address _owner,
        address _provider,
        string memory _name,
        string memory _symbol
    ) internal returns (Synth) {
        Synth synthImplementation = new Synth();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(synthImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,string,string)", _owner, _provider, _name, _symbol
            )
        );

        IProvider(_provider).setXUSD(address(proxy));
        IExchanger(IProvider(_provider).exchanger()).addNewSynth(address(proxy));

        return Synth(address(proxy));
    }

    function _createSynth(
        address _implementation,
        address _owner,
        address _provider,
        string memory _name,
        string memory _symbol
    ) internal returns (Synth) {
        address newSynth =
            Provider(_provider).exchanger().createSynth(_implementation, _owner, _name, _symbol);

        return Synth(newSynth);
    }

    function _deployPool(
        address _owner,
        address _provider,
        address _weth,
        address _debtShares,
        CalculationsInitParams memory params
    ) internal returns (Pool) {
        Pool poolImplementation = new Pool();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(poolImplementation),
            abi.encodeWithSelector(0x4b6d210d, _owner, _provider, _weth, _debtShares, params)
        );

        return Pool(payable(address(proxy)));
    }

    function _deployDebtShares(
        address _owner,
        address _provider,
        string memory _name,
        string memory _symbol
    ) internal returns (DebtShares) {
        DebtShares debtSharesImplementation = new DebtShares();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(debtSharesImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,string,string)", _owner, _provider, _name, _symbol
            )
        );

        return DebtShares(address(proxy));
    }

    function _deployDiaOracleAdapter(address _owner, address _provider, address _diaOracle)
        internal
        returns (DiaOracleAdapter)
    {
        DiaOracleAdapter diaOracleAdapterImplementation = new DiaOracleAdapter();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(diaOracleAdapterImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,address)", _owner, _provider, _diaOracle
            )
        );

        return DiaOracleAdapter(address(proxy));
    }

    function _deployPoolDataProvider(address _owner, address _provider)
        internal
        returns (PoolDataProvider)
    {
        PoolDataProvider poolDataProviderImplementation = new PoolDataProvider();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(poolDataProviderImplementation),
            abi.encodeWithSignature(baseInitializeSignature, _owner, _provider)
        );

        return PoolDataProvider(address(proxy));
    }

    function _deployExchanger(
        address _owner,
        address _provider,
        uint256 _swapFee,
        uint256 _rewarderFee,
        uint256 _burntAtSwap,
        uint256 _settlementDelay
    ) internal returns (Exchanger) {
        Exchanger exchangerImplementation = new Exchanger();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(exchangerImplementation),
            abi.encodeWithSignature(
                "initialize(address,address,uint256,uint256,uint256,uint256)",
                _owner,
                _provider,
                _swapFee,
                _rewarderFee,
                _burntAtSwap,
                _settlementDelay
            )
        );

        return Exchanger(address(proxy));
    }

    function _deploySynthDataProvider(address _owner, address _provider)
        internal
        returns (SynthDataProvider)
    {
        SynthDataProvider synthDataProviderImplementation = new SynthDataProvider();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(synthDataProviderImplementation),
            abi.encodeWithSignature(baseInitializeSignature, _owner, _provider)
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
