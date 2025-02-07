// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IExchanger} from "./IExchanger.sol";

/// @notice SynthDataProvider is a contract that provides data for synths
interface ISynthDataProvider {
    struct AggregateSynthData {
        SynthData[] synthsData;
        uint256 swapFeeForSettle;
        uint256 settleGasCost;
        uint256 baseFee;
        uint256 settlementDelay;
        uint256 burntAtSwap;
        uint256 rewarderFee;
        uint256 swapFee;
        uint256 precision;
        uint256 oraclePrecision;
    }

    struct SynthData {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint256 price;
        uint256 totalSupply;
        UserSynthData userSynthData;
    }

    struct UserSynthData {
        uint256 balance;
        IExchanger.Settlement settlement;
    }

    function aggregateSynthData(address user) external view returns (AggregateSynthData memory);

    function synthData(address synth, address user) external view returns (SynthData memory);

    function synthsData(address user) external view returns (SynthData[] memory);

    function previewSwap(address synthIn, address synthOut, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}
