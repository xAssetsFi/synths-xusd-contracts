// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {UUPSImplementation} from "src/common/_UUPSImplementation.sol";
import {IDebtShares} from "src/interface/IDebtShares.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ArrayLib} from "src/lib/ArrayLib.sol";
/// @notice Rewarder is a contract that distributes rewards to debt shares holders
/// this contract can be used for multiple reward tokens

abstract contract Rewarder is Initializable, ERC20Upgradeable, UUPSImplementation, IDebtShares {
    using SafeERC20 for IERC20;
    using ArrayLib for address[];

    uint32 internal stageDistributionStarted;

    uint32 public constant DURATION = 12 hours;

    address[] public rewardTokens;
    mapping(address => uint256) public periodFinishForToken;
    mapping(address => uint256) public rewardRateForToken;
    mapping(address => uint256) public lastUpdateTimeForToken;
    mapping(address => uint256) public rewardPerTokenStoredForToken;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaidForToken;
    mapping(address => mapping(address => uint256)) public rewardsForToken;

    modifier updateRewards(address account) {
        uint256 len = rewardTokens.length;
        for (uint256 i = 0; i < len; i++) {
            address rt = rewardTokens[i];
            rewardPerTokenStoredForToken[rt] = rewardPerToken(rt);
            lastUpdateTimeForToken[rt] = lastTimeRewardApplicable(rt);
            if (account != address(0)) {
                rewardsForToken[rt][account] = earned(rt, account);
                userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
            }
        }
        _;
    }

    function rewardPerToken(address rt) public view returns (uint256) {
        if (totalSupply() == 0) return rewardPerTokenStoredForToken[rt];

        uint256 tokenPrecision = 10 ** IERC20Metadata(rt).decimals(); // ??? mb 1e18
        return rewardPerTokenStoredForToken[rt]
            + Math.mulDiv(
                lastTimeRewardApplicable(rt) - lastUpdateTimeForToken[rt],
                rewardRateForToken[rt] * tokenPrecision,
                totalSupply()
            );
    }

    function lastTimeRewardApplicable(address rt) public view returns (uint256) {
        return
            block.timestamp < periodFinishForToken[rt] ? block.timestamp : periodFinishForToken[rt];
    }

    function earned(address rt, address account) public view returns (uint256) {
        uint256 tokenPrecision = 10 ** IERC20Metadata(rt).decimals(); // ??? mb 1e18

        return Math.mulDiv(
            balanceOf(account),
            rewardPerToken(rt) - userRewardPerTokenPaidForToken[rt][account],
            tokenPrecision
        ) + rewardsForToken[rt][account];
    }

    function claimRewards() external returns (address[] memory, uint256[] memory) {
        return _claimRewards(msg.sender);
    }

    function _claimRewards(address account)
        internal
        updateRewards(account)
        returns (address[] memory, uint256[] memory)
    {
        uint256 len = rewardTokens.length;
        uint256[] memory amounts = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            address rt = rewardTokens[i];
            uint256 reward = earned(rt, account);
            if (reward > 0 && IERC20(rt).balanceOf(address(this)) >= reward) {
                amounts[i] = reward;
                rewardsForToken[rt][account] = 0;
                IERC20(rt).safeTransfer(account, reward);
                emit RewardPaid(account, rt, reward);
            }
        }

        return (rewardTokens, amounts);
    }

    function addReward(address rt, uint256 reward)
        public
        updateRewards(address(0))
        onlyPlatformOrOwner
    {
        IERC20(rt).safeTransferFrom(msg.sender, address(this), reward);

        uint256 duration;

        if (stageDistributionStarted + DURATION < block.timestamp) {
            stageDistributionStarted = uint32(block.timestamp);
            duration = DURATION;
        } else {
            duration = DURATION - (block.timestamp - stageDistributionStarted);
        }

        uint256 i = rewardTokens.indexOf(rt);
        require(i != type(uint256).max, "rewardTokenIndex not found");

        if (block.timestamp >= periodFinishForToken[rt]) {
            rewardRateForToken[rt] = reward / duration;
        } else {
            uint256 remaining = periodFinishForToken[rt] - block.timestamp;
            uint256 leftover = remaining * rewardRateForToken[rt];
            rewardRateForToken[rt] = (reward + leftover) / duration;
        }
        lastUpdateTimeForToken[rt] = block.timestamp;
        periodFinishForToken[rt] = block.timestamp + duration;

        emit RewardAdded(rt, reward);
    }

    function addRewardToken(address rt) public onlyOwner {
        require(!rewardTokens.contain(rt), "Reward token already exists");
        rewardTokens.push(rt);

        emit NewRewardToken(rt);
    }

    modifier onlyPlatformOrOwner() {
        if (!provider().isPlatform(msg.sender) && msg.sender != owner()) {
            revert Unauthorized();
        }

        _;
    }
}
