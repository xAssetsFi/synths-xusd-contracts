// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Fork} from "../utils/Fork.sol";
import {FileUtils} from "../utils/FileHelpers.sol";
import {Pool} from "src/Pool.sol";
import {Exchanger} from "src/platforms/Synths/Exchanger.sol";

contract SetFeeReceiver is Script, Fork {
    uint32 chainId = 4158;
    address newFeeReceiver = 0x48157f21563aC5BD87b00d4E885bdb728aB619e2;

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
