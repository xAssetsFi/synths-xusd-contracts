// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IProvider} from "src/interface/IProvider.sol";
import {ISynth} from "src/interface/platforms/synths/ISynth.sol";
import {ERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {UUPSProxy} from "src/common/_UUPSProxy.sol";

contract Synth is ISynth, UUPSProxy, ERC20Upgradeable {
    function mint(address to, uint256 amount) external checkAccess noZeroUint(amount) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external checkAccess noZeroUint(amount) {
        _burn(from, amount);
    }

    function initialize(
        address _owner,
        address _provider,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __UUPSProxy_init(_owner, _provider);
        __ERC20_init(_name, _symbol);
        _afterInitialize();
    }

    /**
     * @dev Modifier to check access control for minting and burning.
     *
     * If the contract is the XUSD token, only the platforms and pool can call the function.
     * If the contract is not the XUSD token, only the platforms can call the function.
     */
    modifier checkAccess() {
        IProvider _provider = provider();

        if (address(this) == address(_provider.xusd())) {
            if (!_provider.isPlatform(msg.sender) && msg.sender != address(_provider.pool())) {
                revert Unauthorized();
            }
        } else {
            if (!_provider.isPlatform(msg.sender)) revert Unauthorized();
        }

        _;
    }

    function initialize(address, address) public pure override {
        revert DeprecatedInitializer();
    }

    function _afterInitialize() internal override {
        _registerInterface(type(ISynth).interfaceId);
    }
}
