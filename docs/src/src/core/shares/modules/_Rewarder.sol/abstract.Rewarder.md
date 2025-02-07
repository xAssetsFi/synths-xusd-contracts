# Rewarder

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/core/shares/modules/_Rewarder.sol)

**Inherits:**
Initializable, ERC20Upgradeable, [UUPSProxy](/src/common/_UUPSProxy.sol/abstract.UUPSProxy.md), [IDebtShares](/src/interface/IDebtShares.sol/interface.IDebtShares.md)

Rewarder is a contract that distributes rewards to debt shares holders
this contract can be used for multiple reward tokens

## State Variables

### duration

```solidity
uint256 public constant duration = 10 days;
```

### rewardTokens

```solidity
address[] public rewardTokens;
```

### periodFinishForToken

```solidity
mapping(address => uint256) public periodFinishForToken;
```

### rewardRateForToken

```solidity
mapping(address => uint256) public rewardRateForToken;
```

### lastUpdateTimeForToken

```solidity
mapping(address => uint256) public lastUpdateTimeForToken;
```

### rewardPerTokenStoredForToken

```solidity
mapping(address => uint256) public rewardPerTokenStoredForToken;
```

### userRewardPerTokenPaidForToken

```solidity
mapping(address => mapping(address => uint256)) public userRewardPerTokenPaidForToken;
```

### rewardsForToken

```solidity
mapping(address => mapping(address => uint256)) public rewardsForToken;
```

## Functions

### updateRewards

```solidity
modifier updateRewards(address account);
```

### rewardPerToken

```solidity
function rewardPerToken(address rt) public view returns (uint256);
```

### lastTimeRewardApplicable

```solidity
function lastTimeRewardApplicable(address rt) public view returns (uint256);
```

### earned

```solidity
function earned(address rt, address account) public view returns (uint256);
```

### claimRewards

```solidity
function claimRewards() external updateRewards(msg.sender) returns (address[] memory, uint256[] memory);
```

### addReward

```solidity
function addReward(address rt, uint256 reward) public updateRewards(address(0)) onlyPlatformOrOwner;
```

### addRewardToken

```solidity
function addRewardToken(address rt) public onlyOwner;
```

### onlyPlatformOrOwner

```solidity
modifier onlyPlatformOrOwner();
```
