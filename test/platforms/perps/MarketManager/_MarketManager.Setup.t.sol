// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

import "src/interface/platforms/perps/IMarketManager.sol";

contract MarketManagerSetup is Setup {
    bytes32 public marketKey = "marketKey"; // This is nessecery function to call onlyMarket function from address(this)
}
