// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {
    IERC20,
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ISynth is IERC20, IERC20Metadata {
    function initialize(
        address _owner,
        address _provider,
        string memory _name,
        string memory _symbol
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    error NotTransferable();
}
