// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FileUtils} from "../utils/FileHelpers.sol";
import {DiaOracleAdapter} from "../src/DiaOracleAdapter.sol";
import {Fork} from "../utils/Fork.sol";

contract SetDiaOracle is Script, Fork {
    FileUtils fileUtils = new FileUtils();

    function run() public {
        address contractAddress = fileUtils.readContractAddress(4158, "oracleAdapter");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        fork(4158);

        vm.startBroadcast(privateKey);

        DiaOracleAdapter(contractAddress).setDiaOracle(0x859e221ada7CEBDF5D4040bf6a2B8959C05a4233);
    }
}
