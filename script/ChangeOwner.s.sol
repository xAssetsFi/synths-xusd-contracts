// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Fork} from "../utils/Fork.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FileUtils} from "../utils/FileHelpers.sol";

contract ChangeOwner is Script, Fork {
    uint32 chainId = 4158;
    address newOwner = 0x48157f21563aC5BD87b00d4E885bdb728aB619e2;

    mapping(string keyInJson => bool) shouldSkipChangingOwner;

    address[] contractsToChangeOwner;

    FileUtils fileUtils = new FileUtils();

    function setUp() public {
        shouldSkipChangingOwner["synthImpl"] = true;
        shouldSkipChangingOwner["poolDataProvider"] = true;
        shouldSkipChangingOwner["synthDataProvider"] = true;

        _defineAddressesToChangeOwner();
    }

    function run() public {
        fork(chainId);

        vm.startBroadcast();

        for (uint256 i = 0; i < contractsToChangeOwner.length; i++) {
            Ownable(contractsToChangeOwner[i]).transferOwnership(newOwner);
        }
    }

    /* ======== Helpers ======== */

    function _defineAddressesToChangeOwner() internal {
        string[] memory keys = _extractKeysFromJson();

        for (uint256 i = 0; i < keys.length; i++) {
            _checkAndPush(keys[i]);
        }
    }

    function _extractKeysFromJson() internal returns (string[] memory) {
        string memory file = vm.readFile(fileUtils.pathToContracts());

        return vm.parseJsonKeys(file, string.concat(".", vm.toString(chainId)));
    }

    function _checkAndPush(string memory key) internal {
        if (shouldSkipChangingOwner[key]) {
            return;
        }

        address contractAddress = fileUtils.readContractAddress(chainId, key);

        contractsToChangeOwner.push(contractAddress);
    }
}
