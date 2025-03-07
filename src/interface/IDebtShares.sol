// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IDebtShares is IERC20Metadata {
    event RewardAdded(address indexed token, uint256 indexed amount);
    event RewardPaid(address indexed user, address indexed token, uint256 amount);
    event NewRewardToken(address indexed token);

    /// @notice Mint debt shares
    /// @param to The address to mint the debt shares to
    /// @param amount The amount of debt shares to mint
    /// @dev only platforms can call this function
    function mint(address to, uint256 amount) external;

    /// @notice Burn debt shares
    /// @param from The address to burn the debt shares from
    /// @param amount The amount of debt shares to burn
    /// @dev only platforms can call this function
    function burn(address from, uint256 amount) external;

    /// @notice Notify the target reward amount
    /// @param token The token to notify the reward amount for
    /// @param amount The amount of reward to notify
    /// @dev only platforms and owner can call this function
    function addReward(address token, uint256 amount) external;
}
