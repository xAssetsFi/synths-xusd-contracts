// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Errors} from "src/common/_Errors.sol";

import {ERC165Registry, IERC165} from "src/common/_ERC165Registry.sol";

abstract contract Base is Errors, ERC165Registry {
    uint256 public constant WAD = 1e18;
    uint256 public constant PRECISION = 100_00; // precision for percentage points (100% = 10000)

    /* ======== Modifiers ======== */

    modifier validInterface(address addr, bytes4 interfaceId) {
        if (!IERC165(addr).supportsInterface(interfaceId)) {
            revert InvalidInterface();
        }
        _;
    }

    modifier noZeroAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    modifier noZeroUint(uint256 amount) {
        if (amount == 0) revert ZeroAmount();
        _;
    }

    modifier lessThanPrecision(uint256 value) {
        if (value >= PRECISION) revert ValueTooHigh();
        _;
    }

    modifier greaterThanPrecision(uint256 value) {
        if (value <= PRECISION) revert ValueTooLow();
        _;
    }
}
