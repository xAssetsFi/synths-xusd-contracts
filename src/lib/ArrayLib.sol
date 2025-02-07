// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

library ArrayLib {
    function remove(address[] storage array, address target) internal {
        if (array.length == 1) array.pop();

        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == target) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }

    function getIndex(address[] memory array, address token) internal pure returns (int8) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == token) {
                return int8(uint8(i));
            }
        }

        return -1;
    }
}
