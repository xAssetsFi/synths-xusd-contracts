// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

library MarketLib {
    function getAddress(bytes32 baseAsset) internal pure returns (address) {
        return address(uint160(uint256(baseAsset)));
    }
}
