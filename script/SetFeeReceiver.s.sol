// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Fork} from "../utils/Fork.sol";
import {FileUtils} from "../utils/FileHelpers.sol";
import {Pool} from "src/Pool.sol";
import {Exchanger} from "src/platforms/Synths/Exchanger.sol";

contract SetFeeReceiver is Script, Fork {
    uint32 chainId = 4158;
    address newFeeReceiver = 0x5E9B0205A9f796b47A7FD7024C2b94D84041A494;

    FileUtils fileUtils;

    function run() public {
        fork(chainId);

        fileUtils = new FileUtils();

        _setFeeReceiverInPool();
        _setFeeReceiverInExchanger();
    }

    function _setFeeReceiverInPool() internal {
        address pool = fileUtils.readContractAddress(chainId, "pool");

        vm.broadcast();

        Pool(payable(pool)).setFeeReceiver(newFeeReceiver);
    }

    function _setFeeReceiverInExchanger() internal {
        address exchanger = fileUtils.readContractAddress(chainId, "exchanger");

        vm.broadcast();

        Exchanger(payable(exchanger)).setFeeReceiver(newFeeReceiver);
    }
}
