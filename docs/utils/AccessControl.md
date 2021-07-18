# AccessControl





## Contents
<!-- START doctoc -->
<!-- END doctoc -->



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
  modifier onlyManager(
    bytes32 role
  )
```

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`role` | bytes32 | Role to be checked



