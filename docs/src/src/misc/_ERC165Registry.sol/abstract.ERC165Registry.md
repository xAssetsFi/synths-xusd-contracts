# ERC165Registry

[Git Source](https://dapp-devs.com/ssh://git@git.2222/lumos-labs/xassets/contracts/synths-contracts/blob/0d1cfa460704a82d2d714c759b70770bca8b942b/src/misc/_ERC165Registry.sol)

**Inherits:**
IERC165

_Implementation of the {IERC165} interface.
by {{ numerai }}
from https://github.com/numerai/tournament-contracts
Contracts may inherit from this and call {\_registerInterface} to declare
their support of an interface._

## State Variables

### \_INTERFACE_ID_ERC165

```solidity
bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
```

### \_supportedInterfaces

_Mapping of interface ids to whether or not it's supported._

```solidity
mapping(bytes4 => bool) private _supportedInterfaces;
```

## Functions

### constructor

```solidity
constructor();
```

### supportsInterface

_See [IERC165-supportsInterface](/lib/forge-std/src/mocks/MockERC721.sol/contract.MockERC721.md#supportsinterface).
Time complexity O(1), guaranteed to always use less than 30 000 gas._

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool);
```

### \_registerInterface

\*Registers the contract as an implementer of the interface defined by
`interfaceId`. Support of the actual ERC165 interface is automatic and
registering its interface id is not required.
See [IERC165-supportsInterface](/lib/forge-std/src/mocks/MockERC721.sol/contract.MockERC721.md#supportsinterface).
Requirements:

- `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).\*

```solidity
function _registerInterface(bytes4 interfaceId) internal;
```
