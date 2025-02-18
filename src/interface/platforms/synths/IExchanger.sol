// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IPlatform} from "src/interface/platforms/IPlatform.sol";

/// @notice Exchanger is a contract that allow users to swap one synth for another
interface IExchanger is IPlatform {
    struct Swap {
        uint256 nonce;
        address synthIn;
        address synthOut;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    /// @notice This is used to prevent a front-running attack before a oracle update
    /// @param swaps The list of swaps
    /// @param lastUpdate The last update time. This is time of last swap, used to sum with the settlementDelay to calculate the time when the settlement can be triggered
    /// @param settleReserve The amount of native token that is reserved to pay for user who will trigger the settlement
    /// @notice When some one call the swap function, they will receive some amount of synthOut
    /// @notice When the settlement is triggered, the amount of synthOut will be recalculated based on the current exchange rate and the delta will be burned/minted on user account
    /// @notice If swaps are not empty, users can't transfer their synthOut until the settlement is triggered
    struct PendingSwap {
        Swap[] swaps;
        uint256 lastUpdate;
        uint256 settleReserve;
    }

    /// @notice Swap one synth for another
    /// @param synthIn The address of the synth to send
    /// @param synthOut The address of the synth to receive
    /// @param amountIn The amount of synthIn to swap
    /// @param minAmountOut The minimum amount of synthOut received
    /// @dev User send some native token to cover the gas fee for the settle function
    /// @dev The amount of synthOut received is calculated based on the current exchange rate but can be changed after settlement
    function swap(
        address synthIn,
        address synthOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver
    ) external payable;

    /// @notice Preview the amount of synthOut received
    function previewSwap(address synthIn, address synthOut, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    /// @notice Settle the swap
    /// @param user The address of the user to settle
    /// @param synth The address of the synth to settle
    /// @param settlementCompensationReceiver The address to send the settlement compensation
    /// @dev To prevent a front-running attack before a oracle update, user should call this function after swap to correct the amount of synthOut received
    /// @dev While settlement isn't done, user can't transfer their synthOut
    /// @dev This function can be called by anyone. Gas fee for calling this function is paid by the user who call swap function
    function finishSwap(address user, address synth, address settlementCompensationReceiver)
        external;

    /// @notice Get the pending swap of a user for a specific synth
    /// @param user The address of the user
    /// @param synth The address of the synth
    /// @return pendingSwap The pending swap of the user for the specific synth
    function getPendingSwap(address user, address synth)
        external
        view
        returns (PendingSwap memory pendingSwap);

    /// @notice Check if a synth is registered
    /// @param synth The address of the synth to check
    /// @return isSynth True if the synth is registered, false otherwise
    /// @notice xusd is a synth too
    function isSynth(address synth) external view returns (bool);

    /// @notice Get the swap fee for settle
    /// @return The amount of native token that is reserved to pay for user who will trigger the settlement
    function getFinishSwapFee() external view returns (uint256);

    /// @notice Get the gas cost for settle function
    /// @return The amount of gas that is used for settle function
    function finishSwapGasCost() external view returns (uint256);

    /// @notice Get the settlement delay
    /// @return The delay time before the settlement can be triggered
    function finishSwapDelay() external view returns (uint256);

    /// @notice Get the amount of synth burnt at swap
    /// @notice On each swap some amount will be burnt to decrease the supply of synth and decrease the total debt of the system
    function burntAtSwap() external view returns (uint256);

    /// @notice Get the rewarder fee that will be sent to debt shares contract
    /// @notice On each swap some amount will be send to debt shares contract to distribute rewards to debt shares holders
    function rewarderFee() external view returns (uint256);

    /// @notice Get the swap fee
    /// @notice This is the fee that will be sent to the fee receiver
    function swapFee() external view returns (uint256);

    /// @notice Add a new synth to the exchanger
    /// @param synth The address of the synth to add
    function addNewSynth(address synth) external;

    /// @notice Remove a synth from the exchanger
    /// @param synth The address of the synth to remove
    function removeSynth(address synth) external;

    /// @notice Get the list of synths
    /// @return The list of synths
    function synths() external view returns (address[] memory);

    /// @notice Create a new synth and call addNewSynth function
    /// @param implementation The address of the synth implementation
    /// @param owner The address of the owner of the synth
    /// @param name The name of the synth
    /// @param symbol The symbol of the synth
    function createSynth(
        address implementation,
        address owner,
        string memory name,
        string memory symbol
    ) external returns (address);

    /* ======== Events ======== */
    event SynthAdded(address indexed synth);
    event SynthRemoved(address indexed synth);
    event FinishSwapDelayChanged(uint256 finishSwapDelay);
    event SwapFeeChanged(uint256 swapFee);
    event FeeReceiverChanged(address feeReceiver);
    event BurntAtSwapChanged(uint256 burntAtSwap);
    event RewarderFeeChanged(uint256 rewarderFee);
    event SwapStarted(
        uint256 nonce,
        address synthIn,
        address synthOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address owner,
        address receiver
    );
    event SwapFinished(
        uint256 nonce,
        address synthIn,
        address synthOut,
        uint256 amountOut,
        uint256 minAmountOut,
        address receiver
    );
    event SwapFailed(
        uint256 nonce,
        address synthIn,
        address synthOut,
        uint256 amountOut,
        uint256 minAmountOut,
        address receiver
    );

    /* ======== Errors ======== */

    error InvalidSynth(address synth);
    error NoSwaps();
    error SettlementDelayNotOver();
    error InsufficientGasFee();
    error MaxPendingSettlementReached();
    error SynthAlreadyExists();
    error FeesTooHigh();
}
