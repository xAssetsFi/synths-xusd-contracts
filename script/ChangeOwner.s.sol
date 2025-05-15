// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Fork} from "../utils/Fork.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FileUtils} from "../utils/FileHelpers.sol";
import {console} from "forge-std/console.sol";

struct Contract {
    string keyInJson;
    address contractAddress;
}

contract ChangeOwner is Script, Fork {
    uint32 chainId = 4158;
    address newOwner = 0x1ad157B53f81Db0f4A5588CE61F897e80CFd04b6;

    mapping(string keyInJson => bool) shouldSkipChangingOwner;

    Contract[] contractsToChangeOwner;

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

        console.log("Changing owner of the following contracts:");

        for (uint256 i = 0; i < contractsToChangeOwner.length; i++) {
            console.log("key", contractsToChangeOwner[i].keyInJson);
            console.log("address", contractsToChangeOwner[i].contractAddress);
            console.log("--------------------------------");
            Ownable(contractsToChangeOwner[i].contractAddress).transferOwnership(newOwner);
        }
    }

    /* ======== Helpers ======== */

    function _defineAddressesToChangeOwner() internal {
        string[] memory keys = _extractKeysFromJson();

        for (uint256 i = 0; i < keys.length; i++) {
            _checkAndPush(keys[i]);
        }
    }

    function _extractKeysFromJson() internal view returns (string[] memory) {
        string memory file = vm.readFile(fileUtils.pathToContracts());

        return vm.parseJsonKeys(file, string.concat(".", vm.toString(chainId)));
    }

    function _checkAndPush(string memory key) internal {
        if (shouldSkipChangingOwner[key]) {
            return;
        }

        address contractAddress = fileUtils.readContractAddress(chainId, key);

        Contract memory contractToChangeOwner =
            Contract({keyInJson: key, contractAddress: contractAddress});

        contractsToChangeOwner.push(contractToChangeOwner);
    }
}
