// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ISynth} from "./platforms/synths/ISynth.sol";
import {IExchanger} from "./platforms/synths/IExchanger.sol";
import {IPool} from "./IPool.sol";
import {IOracleAdapter} from "./IOracleAdapter.sol";
import {IPlatform} from "./platforms/IPlatform.sol";

/// @notice The provider is the main contract that allows all contracts to interact with each other by providing the addresses of the other contracts
interface IProvider {
    /* ======== Contract Addresses ======== */

    function pool() external view returns (IPool pool);

    function exchanger() external view returns (IExchanger exchanger);

    function oracle() external view returns (IOracleAdapter oracle);

    function xusd() external view returns (ISynth xusd);

    /* ======== Admin Functions ======== */

    function setXUSD(address xusd) external;

    function setExchanger(address exchanger) external;

    function setPool(address pool) external;

    function setOracle(address oracle) external;

    /* ======== View Functions ======== */

    /// @notice Get the list of platforms
    /// @return The list of platforms
    /// @notice platform it is a contract that can mint and burn xusd (e.g. exchanger)
    function platforms() external view returns (IPlatform[] memory);

    /// @notice Check if a platform is registered
    /// @param platform The address of the platform to check
    /// @return isPlatform True if the platform is registered, false otherwise
    function isPlatform(address platform) external view returns (bool isPlatform);

    /// @notice Check if the protocol is paused
    /// @return isPaused True if the protocol is paused, false otherwise
    /// @notice If protocol is paused, all external users actions are blocked
    function isPaused() external view returns (bool);

    /* ======== Events ======== */

    event XUSDChanged(address previous, address current);
    event ExchangerChanged(address previous, address current);
    event OracleChanged(address previous, address current);
    event PoolChanged(address previous, address current);
    event WethGatewayChanged(address previous, address current);
    event NewPlatform(address platform);
    event PlatformRemoved(address platform);

    error PlatformAlreadyAdded();
    error PlatformNotFound();
}
