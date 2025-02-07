// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "test/Setup.sol";

import {Provider} from "src/periphery/Provider.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ProviderV2 is Provider {
    uint256 public newVariable;

    function initialize(address, address) public initializer {
        newVariable = 2;
    }

    function reinitialize(uint64 version) public reinitializer(version) {
        newVariable = version;
    }

    function newFunction() public pure returns (uint256) {
        return 1;
    }
}

contract UpgradeTest is Setup {
    function test_upgrade_withoutReinitialize() public {
        vm.expectRevert();
        ProviderV2(address(provider)).newFunction();

        address newImplementation = address(new ProviderV2());

        provider.upgradeToAndCall(newImplementation, "");

        assertEq(provider.implementation(), newImplementation);
        assertEq(ProviderV2(address(provider)).newFunction(), 1);
    }

    function test_upgrade_withInitialize() public {
        address newImplementation = address(new ProviderV2());

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        provider.upgradeToAndCall(
            newImplementation,
            abi.encodeWithSignature("initialize(address,address)", address(0), address(0))
        );
    }

    function test_upgrade_withReinitialize() public {
        address newImplementation = address(new ProviderV2());

        provider.upgradeToAndCall(
            newImplementation, abi.encodeWithSignature("reinitialize(uint64)", 2)
        );

        assertEq(ProviderV2(address(provider)).newVariable(), 2);
    }

    function test_upgrade_revertIfNotOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        provider.upgradeToAndCall(address(0x1), "");
    }

    function test_initialize_revertIfAlreadyInitialized() public {
        vm.expectRevert();
        ProviderV2(address(provider)).initialize(address(0), address(0));
    }
}
