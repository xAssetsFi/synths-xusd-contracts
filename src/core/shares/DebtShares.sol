// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Rewarder} from "./modules/_Rewarder.sol";

import {IDebtShares} from "src/interface/IDebtShares.sol";

/// @notice DebtShares is a contract that manages the debt shares
/// Debt shares are minted when a user mint xusd and burned when a user burn xusd
/// Only pool contract can transfer debt shares
contract DebtShares is Rewarder {
    function mint(address to, uint256 amount)
        external
        onlyPool
        updateRewards(to)
        noZeroUint(amount)
    {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount)
        external
        onlyPool
        updateRewards(from)
        noZeroUint(amount)
    {
        _claimRewards(from);
        _burn(from, amount);
    }

    function _update(address from, address to, uint256 amount) internal override onlyPool {
        if (from != address(0) && to != address(0)) revert UnAllowedAction();

        super._update(from, to, amount);
    }

    modifier onlyPool() {
        if (msg.sender != address(provider().pool())) revert Unauthorized();
        _;
    }

    function initialize(
        address _owner,
        address _provider,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __UUPSProxy_init(_owner, _provider);
        __ERC20_init(_name, _symbol);
        stageDistributionStarted = uint32(block.timestamp);
        _afterInitialize();
    }

    function _afterInitialize() internal override {
        _registerInterface(type(IDebtShares).interfaceId);
    }

    function initialize(address, address) public override initializer {
        revert DeprecatedInitializer();
    }
}
