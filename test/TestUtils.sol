// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fork} from "../utils/Fork.sol";

contract TestUtils is Fork, Test {
    uint256 public constant WAD = 1e18;
    uint256 public constant PRECISION = 10000;

    // in some fuzzing cases, the amount is too small (swap 10 wei xusd(1$) on xau(3000$) will cause mint 0 xau and tx revert due to zeroAmount error),
    // so we need to set a dust value to avoid the fuzzing failure
    uint256 public fuzzingDust = 1e4;

    function _configureDefaultForkBlockNumber() internal override {
        defaultForkBlockNumber[1] = 20540766; // 16 aug 2024
        defaultForkBlockNumber[10] = 124104713; // 16 aug 2024
        defaultForkBlockNumber[56] = 41411949; // 16 aug 2024
        defaultForkBlockNumber[137] = 60657859; // 16 aug 2024
        defaultForkBlockNumber[5000] = 67856441; // 16 aug 2024
        defaultForkBlockNumber[8453] = 18509444; // 16 aug 2024
        defaultForkBlockNumber[42161] = 243590872; // 16 aug 2024
    }

    function setUp() public {
        _setUp();
        _afterSetup();
    }

    function _setUp() internal virtual {}

    function _afterSetup() internal virtual {}
}
