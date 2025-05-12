// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IExchanger} from "../platforms/synths/IExchanger.sol";

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
        IExchanger.PendingSwap pendingSwap;
    }

    /// @notice Aggregates data for all synths and swap parameters for a user.
    /// @param user The address of the user to query.
    /// @return data The aggregate data including all synths and swap parameters.
    function aggregateSynthData(address user)
        external
        view
        returns (AggregateSynthData memory data);

    /// @notice Returns detailed data for a specific synth and user.
    /// @param synth The address of the synth token.
    /// @param user The address of the user to query.
    /// @return data The synth data including user-specific info.
    function synthData(address synth, address user) external view returns (SynthData memory data);

    /// @notice Returns data for all synths for a user.
    /// @param user The address of the user to query.
    /// @return data Array of synth data for each synth.
    function synthsData(address user) external view returns (SynthData[] memory data);

    /// @notice Previews the output amount for a synth-to-synth swap.
    /// @param synthIn The address of the input synth token.
    /// @param synthOut The address of the output synth token.
    /// @param amountIn The amount of input synth to swap.
    /// @return amountOut The estimated amount of output synth received.
    function previewSwap(address synthIn, address synthOut, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}
