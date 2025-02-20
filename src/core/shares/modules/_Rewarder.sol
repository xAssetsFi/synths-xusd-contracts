// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {UUPSImplementation} from "src/common/_UUPSImplementation.sol";
import {IDebtShares} from "src/interface/IDebtShares.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ArrayLib, INDEX_NOT_FOUND} from "src/lib/ArrayLib.sol";
/// @notice Rewarder is a contract that distributes rewards to debt shares holders
/// this contract can be used for multiple reward tokens

abstract contract Rewarder is Initializable, ERC20Upgradeable, UUPSImplementation, IDebtShares {
    struct RewardData {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    using SafeERC20 for IERC20;
    using ArrayLib for address[];

    uint32 internal stageDistributionStarted;

    uint32 public constant DURATION = 12 hours;

    address[] public rewardTokens;

    mapping(address => RewardData) public rewardData;

    modifier updateRewards(address account) {
        uint256 len = rewardTokens.length;
        for (uint256 i = 0; i < len; i++) {
            address rt = rewardTokens[i];
            RewardData storage data = rewardData[rt];
            data.rewardPerTokenStored = rewardPerToken(rt);
            data.lastUpdateTime = lastTimeRewardApplicable(rt);
            if (account != address(0)) {
                data.rewards[account] = earned(rt, account);
                data.userRewardPerTokenPaid[account] = data.rewardPerTokenStored;
            }
        }
        _;
    }

    function rewardPerToken(address rt) public view returns (uint256) {
        RewardData storage data = rewardData[rt];

        if (totalSupply() == 0) return data.rewardPerTokenStored;

        return data.rewardPerTokenStored
            + Math.mulDiv(
                lastTimeRewardApplicable(rt) - data.lastUpdateTime, data.rewardRate * WAD, totalSupply()
            );
    }

    function lastTimeRewardApplicable(address rt) public view returns (uint256) {
        RewardData storage data = rewardData[rt];
        return block.timestamp < data.periodFinish ? block.timestamp : data.periodFinish;
    }

    function earned(address rt, address account) public view returns (uint256) {
        RewardData storage data = rewardData[rt];

        return Math.mulDiv(
            balanceOf(account), rewardPerToken(rt) - data.userRewardPerTokenPaid[account], WAD
        ) + data.rewards[account];
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
                rewardData[rt].rewards[account] = 0;
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
        require(i != INDEX_NOT_FOUND, "rewardTokenIndex not found");

        RewardData storage data = rewardData[rt];

        if (block.timestamp >= data.periodFinish) {
            data.rewardRate = reward / duration;
        } else {
            uint256 remaining = data.periodFinish - block.timestamp;
            uint256 leftover = remaining * data.rewardRate;
            data.rewardRate = (reward + leftover) / duration;
        }
        data.lastUpdateTime = block.timestamp;
        data.periodFinish = block.timestamp + duration;

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
