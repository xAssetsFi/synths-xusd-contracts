# IProvider

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/969beda74f0f892980053e9edc62c163df24916a/src/interface/IProvider.sol)

The provider is the main contract that allows all contracts to interact with each other by providing the addresses of the other contracts

## Functions

### pool

```solidity
function pool() external view returns (IPool pool);
```

### exchanger

```solidity
function exchanger() external view returns (IExchanger exchanger);
```

### oracle

```solidity
function oracle() external view returns (IOracleAdapter oracle);
```

### xusd

```solidity
function xusd() external view returns (ISynth xusd);
```

### setXUSD

```solidity
function setXUSD(address xusd) external;
```

### setExchanger

```solidity
function setExchanger(address exchanger) external;
```

### setPool

```solidity
function setPool(address pool) external;
```

### setOracle

```solidity
function setOracle(address oracle) external;
```

### platforms

Get the list of platforms

platform it is a contract that can mint and burn xusd (e.g. exchanger)

```solidity
function platforms() external view returns (IPlatform[] memory);
```

**Returns**

| Name     | Type          | Description           |
| -------- | ------------- | --------------------- |
| `<none>` | `IPlatform[]` | The list of platforms |

### isPlatform

Check if a platform is registered

```solidity
function isPlatform(address platform) external view returns (bool isPlatform);
```

**Parameters**

| Name       | Type      | Description                          |
| ---------- | --------- | ------------------------------------ |
| `platform` | `address` | The address of the platform to check |

**Returns**

| Name         | Type   | Description                                         |
| ------------ | ------ | --------------------------------------------------- |
| `isPlatform` | `bool` | True if the platform is registered, false otherwise |

### isPaused

Check if the protocol is paused

If protocol is paused, all external users actions are blocked

```solidity
function isPaused() external view returns (bool);
```

**Returns**

| Name     | Type   | Description                                              |
| -------- | ------ | -------------------------------------------------------- |
| `<none>` | `bool` | isPaused True if the protocol is paused, false otherwise |

## Events

### XUSDChanged

```solidity
event XUSDChanged(address previous, address current);
```

### ExchangerChanged

```solidity
event ExchangerChanged(address previous, address current);
```

### OracleChanged

```solidity
event OracleChanged(address previous, address current);
```

### PoolChanged

```solidity
event PoolChanged(address previous, address current);
```

### WethGatewayChanged

```solidity
event WethGatewayChanged(address previous, address current);
```

### NewPlatform

```solidity
event NewPlatform(address platform);
```
