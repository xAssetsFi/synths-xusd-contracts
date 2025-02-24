// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IPool} from "src/interface/IPool.sol";

import {INDEX_NOT_FOUND} from "src/lib/ArrayLib.sol";

library PoolArrayLib {
    function remove(IPool.CollateralData[] storage array, address token) internal returns (bool) {
        uint256 len = array.length;
        for (uint256 i = 0; i < len; i++) {
            if (array[i].token == token) {
                if (len > 1) {
                    array[i] = array[len - 1];
                }
                array.pop();
                return true;
            }
        }

        return false;
    }

    function indexOf(IPool.CollateralData[] memory array, address token)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i].token == token) return i;
        }

        return INDEX_NOT_FOUND;
    }

    function contain(IPool.CollateralData[] memory array, address token)
        internal
        pure
        returns (bool)
    {
        return indexOf(array, token) != INDEX_NOT_FOUND;
    }
}
