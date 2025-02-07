// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IPool} from "src/interface/IPool.sol";

library PoolArrayLib {
    function remove(IPool.CollateralData[] storage array, address target) internal {
        if (array.length == 1) array.pop();

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i].token == target) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }

    function getIndex(IPool.CollateralData[] memory array, address token)
        internal
        pure
        returns (int8)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i].token == token) {
                return int8(uint8(i));
            }
        }

        return -1;
    }
}
