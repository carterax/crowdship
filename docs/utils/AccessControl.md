# AccessControl





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| MANAGER | bytes32 |


## Modifiers

### onlyAdmin
> Restricted to members of the admin role.

#### Declaration
```solidity
  modifier onlyAdmin
```


### onlyManager
> Restricted to members of the manager role.

#### Declaration
```solidity
  modifier onlyManager
```



## Functions

### addRole
>        Add an account to the role. Restricted to admins.


#### Declaration
```solidity
  function addRole(
    address _account,
    bytes32 _role
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_account` | address | Address of user being assigned role
|`_role` | bytes32 |   Role being assigned
---  
### removeRole
>        Remove an account from the role. Restricted to admins.


#### Declaration
```solidity
  function removeRole(
    address _account,
    bytes32 _role
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_account` | address | Address of user whose role is being removed
|`_role` | bytes32 |   Role being removed
---  
### renounceAdmin
> Remove oneself from the admin role.

#### Declaration
```solidity
  function renounceAdmin(
  ) external
```

#### Modifiers:
No modifiers


---  


