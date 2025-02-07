# ISynthDataProvider

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/platforms/synths/ISynthDataProvider.sol)

SynthDataProvider is a contract that provides data for synths

## Functions

### aggregateSynthData

```solidity
function aggregateSynthData(address user) external view returns (AggregateSynthData memory);
```

### synthData

```solidity
function synthData(address synth, address user) external view returns (SynthData memory);
```

### synthsData

```solidity
function synthsData(address user) external view returns (SynthData[] memory);
```

### previewSwap

```solidity
function previewSwap(address synthIn, address synthOut, uint256 amountIn) external view returns (uint256 amountOut);
```

## Structs

### AggregateSynthData

```solidity
struct AggregateSynthData {
    SynthData[] synthsData;
    uint256 swapFeeForSettle;
    uint256 settleGasCost;
    uint256 baseFee;
    uint256 settlementDelay;
    uint256 burntAtSwap;
    uint256 rewarderFee;
    uint256 swapFee;
    uint256 precision;
    uint256 oraclePrecision;
}
```

### SynthData

```solidity
struct SynthData {
    address token;
    string name;
    string symbol;
    uint8 decimals;
    uint256 price;
    uint256 totalSupply;
    UserSynthData userSynthData;
}
```

### UserSynthData

```solidity
struct UserSynthData {
    uint256 balance;
    IExchanger.Settlement settlement;
}
```
