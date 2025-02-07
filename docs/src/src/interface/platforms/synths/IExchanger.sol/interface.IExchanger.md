# IExchanger

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/platforms/synths/IExchanger.sol)

**Inherits:**
[IPlatform](/src/interface/platforms/IPlatform.sol/interface.IPlatform.md)

Exchanger is a contract that allow users to swap one synth for another

## Functions

### swap

Swap one synth for another

_User send some native token to cover the gas fee for the settle function_

_The amount of synthOut received is calculated based on the current exchange rate but can be changed after settlement_

```solidity
function swap(address synthIn, address synthOut, uint256 amountIn, address receiver)
    external
    payable
    returns (uint256 amountOut);
```

**Parameters**

| Name       | Type      | Description                         |
| ---------- | --------- | ----------------------------------- |
| `synthIn`  | `address` | The address of the synth to send    |
| `synthOut` | `address` | The address of the synth to receive |
| `amountIn` | `uint256` | The amount of synthIn to swap       |
| `receiver` | `address` |                                     |

**Returns**

| Name        | Type      | Description                     |
| ----------- | --------- | ------------------------------- |
| `amountOut` | `uint256` | The amount of synthOut received |

### previewSwap

Preview the amount of synthOut received

```solidity
function previewSwap(address synthIn, address synthOut, uint256 amountIn) external view returns (uint256 amountOut);
```

### settle

Settle the swap

_To prevent a front-running attack before a oracle update, user should call this function after swap to correct the amount of synthOut received_

_While settlement isn't done, user can't transfer their synthOut_

_This function can be called by anyone. Gas fee for calling this function is paid by the user who call swap function_

```solidity
function settle(address user, address synth, address settlementCompensationReceiver) external;
```

**Parameters**

| Name                             | Type      | Description                                     |
| -------------------------------- | --------- | ----------------------------------------------- |
| `user`                           | `address` | The address of the user to settle               |
| `synth`                          | `address` | The address of the synth to settle              |
| `settlementCompensationReceiver` | `address` | The address to send the settlement compensation |

### getSettlement

Get the settlement of a user for a specific synth

```solidity
function getSettlement(address user, address synth) external view returns (Settlement memory settlement);
```

**Parameters**

| Name    | Type      | Description              |
| ------- | --------- | ------------------------ |
| `user`  | `address` | The address of the user  |
| `synth` | `address` | The address of the synth |

**Returns**

| Name         | Type         | Description                                       |
| ------------ | ------------ | ------------------------------------------------- |
| `settlement` | `Settlement` | The settlement of the user for the specific synth |

### isSynth

Check if a synth is registered

xusd is a synth too

```solidity
function isSynth(address synth) external view returns (bool);
```

**Parameters**

| Name    | Type      | Description                       |
| ------- | --------- | --------------------------------- |
| `synth` | `address` | The address of the synth to check |

**Returns**

| Name     | Type   | Description                                              |
| -------- | ------ | -------------------------------------------------------- |
| `<none>` | `bool` | isSynth True if the synth is registered, false otherwise |

### getSwapFeeForSettle

Get the swap fee for settle

```solidity
function getSwapFeeForSettle() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                                                                                 |
| -------- | --------- | ------------------------------------------------------------------------------------------- |
| `<none>` | `uint256` | The amount of native token that is reserved to pay for user who will trigger the settlement |

### settleFunctionGasCost

Get the gas cost for settle function

```solidity
function settleFunctionGasCost() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                                        |
| -------- | --------- | -------------------------------------------------- |
| `<none>` | `uint256` | The amount of gas that is used for settle function |

### settlementDelay

Get the settlement delay

```solidity
function settlementDelay() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                                           |
| -------- | --------- | ----------------------------------------------------- |
| `<none>` | `uint256` | The delay time before the settlement can be triggered |

### burntAtSwap

Get the amount of synth burnt at swap

On each swap some amount will be burnt to decrease the supply of synth and decrease the total debt of the system

```solidity
function burntAtSwap() external view returns (uint256);
```

### rewarderFee

Get the rewarder fee that will be sent to debt shares contract

On each swap some amount will be send to debt shares contract to distribute rewards to debt shares holders

```solidity
function rewarderFee() external view returns (uint256);
```

### swapFee

Get the swap fee

This is the fee that will be sent to the fee receiver

```solidity
function swapFee() external view returns (uint256);
```

### addNewSynth

Add a new synth to the exchanger

```solidity
function addNewSynth(address synth) external;
```

**Parameters**

| Name    | Type      | Description                     |
| ------- | --------- | ------------------------------- |
| `synth` | `address` | The address of the synth to add |

### removeSynth

Remove a synth from the exchanger

```solidity
function removeSynth(address synth) external;
```

**Parameters**

| Name    | Type      | Description                        |
| ------- | --------- | ---------------------------------- |
| `synth` | `address` | The address of the synth to remove |

### synths

Get the list of synths

```solidity
function synths() external view returns (address[] memory);
```

**Returns**

| Name     | Type        | Description        |
| -------- | ----------- | ------------------ |
| `<none>` | `address[]` | The list of synths |

### isTransferable

Check if a synth is transferable for a user

See the settlement struct for more details

```solidity
function isTransferable(address synth, address user) external view returns (bool);
```

**Parameters**

| Name    | Type      | Description                       |
| ------- | --------- | --------------------------------- |
| `synth` | `address` | The address of the synth to check |
| `user`  | `address` | The address of the user to check  |

**Returns**

| Name     | Type   | Description                                                       |
| -------- | ------ | ----------------------------------------------------------------- |
| `<none>` | `bool` | isTransferable True if the synth is transferable, false otherwise |

### createSynth

Create a new synth and call addNewSynth function

```solidity
function createSynth(address implementation, address owner, string memory name, string memory symbol)
    external
    returns (address);
```

**Parameters**

| Name             | Type      | Description                             |
| ---------------- | --------- | --------------------------------------- |
| `implementation` | `address` | The address of the synth implementation |
| `owner`          | `address` | The address of the owner of the synth   |
| `name`           | `string`  | The name of the synth                   |
| `symbol`         | `string`  | The symbol of the synth                 |

## Events

### SettlementDelayChanged

```solidity
event SettlementDelayChanged(uint256 settlementDelay);
```

### SwapFeeChanged

```solidity
event SwapFeeChanged(uint256 swapFee);
```

### FeeReceiverChanged

```solidity
event FeeReceiverChanged(address feeReceiver);
```

### BurntAtSwapChanged

```solidity
event BurntAtSwapChanged(uint256 burntAtSwap);
```

### RewarderFeeChanged

```solidity
event RewarderFeeChanged(uint256 rewarderFee);
```

### SwapSettled

```solidity
event SwapSettled(
    address user, address synth, uint256 nonce, address synthIn, address synthOut, uint256 amountOld, uint256 amountNew
);
```

### Swapped

```solidity
event Swapped(
    uint256 nonce,
    address synthIn,
    address synthOut,
    uint256 amountIn,
    uint256 amountOut,
    address owner,
    address receiver
);
```

### SynthAdded

```solidity
event SynthAdded(address indexed synth);
```

### SynthRemoved

```solidity
event SynthRemoved(address indexed synth);
```

## Errors

### InvalidSynth

```solidity
error InvalidSynth(address synth);
```

### NoSwaps

```solidity
error NoSwaps();
```

### SettlementDelayNotOver

```solidity
error SettlementDelayNotOver();
```

### InsufficientGasFee

```solidity
error InsufficientGasFee();
```

## Structs

### Swap

```solidity
struct Swap {
    uint256 nonce;
    address synthIn;
    address synthOut;
    uint256 amountIn;
    uint256 amountOut;
}
```

### Settlement

This is used to prevent a front-running attack before a oracle update

When some one call the swap function, they will receive some amount of synthOut

When the settlement is triggered, the amount of synthOut will be recalculated based on the current exchange rate and the delta will be burned/minted on user account

If swaps are not empty, users can't transfer their synthOut until the settlement is triggered

```solidity
struct Settlement {
    Swap[] swaps;
    uint256 lastUpdate;
    uint256 settleReserve;
}
```

**Properties**

| Name            | Type      | Description                                                                                                                                      |
| --------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `swaps`         | `Swap[]`  | The list of swaps                                                                                                                                |
| `lastUpdate`    | `uint256` | The last update time. This is time of last swap, used to sum with the settlementDelay to calculate the time when the settlement can be triggered |
| `settleReserve` | `uint256` | The amount of native token that is reserved to pay for user who will trigger the settlement                                                      |
