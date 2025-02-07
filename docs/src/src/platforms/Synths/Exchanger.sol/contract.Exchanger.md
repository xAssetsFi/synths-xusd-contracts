# Exchanger

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/platforms/Synths/Exchanger.sol)

**Inherits:**
[IExchanger](/src/interface/platforms/synths/IExchanger.sol/interface.IExchanger.md), [UUPSProxy](/src/common/_UUPSProxy.sol/abstract.UUPSProxy.md)

## State Variables

### \_synths

```solidity
address[] private _synths;
```

### \_settlements

```solidity
mapping(address user => mapping(address synthOut => Settlement)) private _settlements;
```

### isSynth

```solidity
mapping(address => bool) public isSynth;
```

### swapNonce

```solidity
uint256 public swapNonce;
```

### burntAtSwap

With each swap the user will receive less synthOut,
this shortfall is burned and is not considered a commission.
This is to decrease the total debt of users who have a debt position in pool contract.

```solidity
uint256 public burntAtSwap;
```

### rewarderFee

```solidity
uint256 public rewarderFee;
```

### swapFee

```solidity
uint256 public swapFee;
```

### feeReceiver

```solidity
address public feeReceiver;
```

### settlementDelay

```solidity
uint256 public settlementDelay;
```

### settleFunctionGasCost

```solidity
uint256 public settleFunctionGasCost;
```

## Functions

### initialize

```solidity
function initialize(
    address _owner,
    address _provider,
    uint256 _swapFee,
    uint256 _rewarderFee,
    uint256 _burntAtSwap,
    uint256 _settlementDelay
) public initializer;
```

### synths

```solidity
function synths() external view returns (address[] memory);
```

### getSwapFeeForSettle

```solidity
function getSwapFeeForSettle() public view returns (uint256);
```

### swap

```solidity
function swap(address synthIn, address synthOut, uint256 amountIn, address receiver)
    external
    payable
    noPaused
    onlySynth(synthIn)
    onlySynth(synthOut)
    noZeroUint(amountIn)
    returns (uint256 amountOut);
```

### \_swap

```solidity
function _swap(address synthIn, address synthOut, uint256 amountIn, uint256 amountOut, address owner, address receiver)
    internal;
```

### \_chargeFee

```solidity
function _chargeFee(address synthIn, uint256 amountIn, address owner) internal returns (uint256);
```

### \_chargeFeeInXUSD

```solidity
function _chargeFeeInXUSD(address synthIn, uint256 amountIn, address owner, address receiver)
    internal
    returns (uint256 amountOut);
```

### \_calcFee

```solidity
function _calcFee(uint256 amountIn) internal view returns (uint256 _swapFee, uint256 _rewarderFee, uint256 _burned);
```

### settle

```solidity
function settle(address user, address synth, address settlementCompensationReceiver)
    external
    noPaused
    onlySynth(synth);
```

### totalFunds

```solidity
function totalFunds() public view returns (uint256 tf);
```

### previewSwap

```solidity
function previewSwap(address synthIn, address synthOut, uint256 amountIn)
    public
    view
    onlySynth(synthIn)
    onlySynth(synthOut)
    returns (uint256 amountOut);
```

### \_previewSwap

```solidity
function _previewSwap(address synthIn, address synthOut, uint256 amountIn) internal view returns (uint256 amountOut);
```

### getSettlement

```solidity
function getSettlement(address user, address synth)
    external
    view
    onlySynth(synth)
    returns (Settlement memory settlement);
```

### isTransferable

```solidity
function isTransferable(address synth, address user) external view returns (bool);
```

### onlySynth

```solidity
modifier onlySynth(address synth);
```

### createSynth

```solidity
function createSynth(address _implementation, address _owner, string memory _name, string memory _symbol)
    external
    onlyOwner
    returns (address);
```

### addNewSynth

```solidity
function addNewSynth(address _synth)
    public
    onlyOwner
    noZeroAddress(_synth)
    validInterface(_synth, type(ISynth).interfaceId);
```

### removeSynth

```solidity
function removeSynth(address _synth) external onlyOwner onlySynth(_synth);
```

### setSettlementDelay

```solidity
function setSettlementDelay(uint256 _settlementDelay) external onlyOwner;
```

### setSwapFee

```solidity
function setSwapFee(uint256 _swapFee) external onlyOwner;
```

### setFeeReceiver

```solidity
function setFeeReceiver(address _feeReceiver) external onlyOwner noZeroAddress(_feeReceiver);
```

### setBurntAtSwap

```solidity
function setBurntAtSwap(uint256 _burntAtSwap) external onlyOwner;
```

### setRewarderFee

```solidity
function setRewarderFee(uint256 _rewarderFee) external onlyOwner;
```

### initialize

```solidity
function initialize(address, address) public override initializer;
```

### \_afterInitialize

```solidity
function _afterInitialize() internal override;
```
