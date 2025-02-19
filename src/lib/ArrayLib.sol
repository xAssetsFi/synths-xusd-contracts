// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library ArrayLib {
    function remove(address[] storage array, address addressToRemove) internal returns (bool) {
        uint256 len = array.length;
        for (uint256 i = 0; i < len; i++) {
            if (array[i] == addressToRemove) {
                if (len > 1) {
                    array[i] = array[len - 1];
                }
                array.pop();
                return true;
            }
        }

        return false;
    }

    function indexOf(address[] memory array, address addressToFind)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == addressToFind) return i;
        }

        return type(uint256).max;
    }

    function contain(address[] memory array, address addressToFind) internal pure returns (bool) {
        return indexOf(array, addressToFind) != type(uint256).max;
    }
}
