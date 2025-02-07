// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {UUPSProxy} from "src/common/_UUPSProxy.sol";

import {ISynth} from "src/interface/platforms/synths/ISynth.sol";
import {IPool} from "src/interface/IPool.sol";
import {ISynthDataProvider} from "src/interface/platforms/synths/ISynthDataProvider.sol";

import {IExchanger} from "src/interface/platforms/synths/IExchanger.sol";

import {PoolArrayLib} from "src/lib/PoolArrayLib.sol";

contract SynthDataProvider is ISynthDataProvider, UUPSProxy {
    using PoolArrayLib for IPool.CollateralData[];

    function aggregateSynthData(address user)
        public
        view
        returns (AggregateSynthData memory data)
    {
        IExchanger exchanger = provider().exchanger();

        data = AggregateSynthData(
            synthsData(user),
            exchanger.getSwapFeeForSettle(),
            exchanger.settleFunctionGasCost(),
            block.basefee,
            exchanger.settlementDelay(),
            exchanger.burntAtSwap(),
            exchanger.rewarderFee(),
            exchanger.swapFee(),
            PRECISION,
            provider().oracle().precision()
        );
    }

    function synthData(address synth, address user) public view returns (SynthData memory data) {
        ISynth token = ISynth(synth);
        data = SynthData(
            synth,
            token.name(),
            token.symbol(),
            token.decimals(),
            provider().oracle().getPrice(synth),
            token.totalSupply(),
            getUserSynthData(synth, user)
        );
    }

    function synthsData(address user) public view returns (SynthData[] memory) {
        address[] memory synths = provider().exchanger().synths();
        SynthData[] memory data = new SynthData[](synths.length);
        for (uint256 i = 0; i < synths.length; i++) {
            data[i] = synthData(synths[i], user);
        }
        return data;
    }

    function getUserSynthData(address synth, address user)
        public
        view
        returns (UserSynthData memory data)
    {
        data = UserSynthData(
            ISynth(synth).balanceOf(user), provider().exchanger().getSettlement(user, synth)
        );
    }

    function previewSwap(address synthIn, address synthOut, uint256 amountIn)
        public
        view
        returns (uint256 amountOut)
    {
        return provider().exchanger().previewSwap(synthIn, synthOut, amountIn);
    }

    function _afterInitialize() internal override {
        _registerInterface(type(ISynthDataProvider).interfaceId);
    }
}
