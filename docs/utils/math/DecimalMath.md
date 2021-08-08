# DecimalMath



> Implements simple fixed point math mul and div operations for 27 decimals.

## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| UNIT | uint256 |



## Functions

### toUFixed
> Creates a fixed point number from an unsiged integer. `toUFixed(1) = 10^-27`
Converting from fixed point to integer can be done with `UFixed.value / UNIT` and `UFixed.value % UNIT`

#### Declaration
```solidity
  function toUFixed(
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers


---  
### eq
> Equal to.

#### Declaration
```solidity
  function eq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### eq
> Equal to.

#### Declaration
```solidity
  function eq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### eq
> Equal to.

#### Declaration
```solidity
  function eq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### gt
> Greater than.

#### Declaration
```solidity
  function gt(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### gt
> Greater than.

#### Declaration
```solidity
  function gt(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### gt
> Greater than.

#### Declaration
```solidity
  function gt(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### geq
> Greater or equal.

#### Declaration
```solidity
  function geq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### geq
> Greater or equal.

#### Declaration
```solidity
  function geq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### geq
> Greater or equal.

#### Declaration
```solidity
  function geq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### lt
> Less than.

#### Declaration
```solidity
  function lt(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### lt
> Less than.

#### Declaration
```solidity
  function lt(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### lt
> Less than.

#### Declaration
```solidity
  function lt(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### leq
> Less or equal.

#### Declaration
```solidity
  function leq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### leq
> Less or equal.

#### Declaration
```solidity
  function leq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### leq
> Less or equal.

#### Declaration
```solidity
  function leq(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### muld
> Multiplies x and y.


#### Declaration
```solidity
  function muld(
    uint256 x,
    struct DecimalMath.UFixed y
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | uint256 | An unsigned integer.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`An` | unsigned integer.---  
### muld
> Multiplies x and y.


#### Declaration
```solidity
  function muld(
    struct DecimalMath.UFixed x,
    struct DecimalMath.UFixed y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### muld
> Multiplies x and y.


#### Declaration
```solidity
  function muld(
    struct DecimalMath.UFixed x,
    uint256 y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`y` | uint256 | An unsigned integer.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### divd
> Divides x by y.


#### Declaration
```solidity
  function divd(
    uint256 x,
    struct DecimalMath.UFixed y
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | uint256 | An unsigned integer.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`An` | unsigned integer.---  
### divd
> Divides x by y.


#### Declaration
```solidity
  function divd(
    struct DecimalMath.UFixed x,
    struct DecimalMath.UFixed y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### divd
> Divides x by y.


#### Declaration
```solidity
  function divd(
    struct DecimalMath.UFixed x,
    uint256 y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`y` | uint256 | An unsigned integer.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### divd
> Divides x by y.


#### Declaration
```solidity
  function divd(
    uint256 x,
    uint256 y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | uint256 | An unsigned integer.
|`y` | uint256 | An unsigned integer.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### addd
> Adds x and y.


#### Declaration
```solidity
  function addd(
    struct DecimalMath.UFixed x,
    struct DecimalMath.UFixed y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### addd
> Adds x and y.


#### Declaration
```solidity
  function addd(
    struct DecimalMath.UFixed x,
    uint256 y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`y` | uint256 | An unsigned integer.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### subd
> Subtracts x and y.


#### Declaration
```solidity
  function subd(
    struct DecimalMath.UFixed x,
    struct DecimalMath.UFixed y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### subd
> Subtracts x and y.


#### Declaration
```solidity
  function subd(
    struct DecimalMath.UFixed x,
    uint256 y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`y` | uint256 | An unsigned integer.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### subd
> Subtracts x and y.


#### Declaration
```solidity
  function subd(
    uint256 x,
    struct DecimalMath.UFixed y
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | uint256 | An unsigned integer.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`A` | fixed point number.---  
### divdrup
> Divides x between y, rounding up to the closest representable number.


#### Declaration
```solidity
  function divdrup(
    uint256 x,
    struct DecimalMath.UFixed y
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | uint256 | An unsigned integer.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`An` | unsigned integer.---  
### muldrup
> Multiplies x by y, rounding up to the closest representable number.


#### Declaration
```solidity
  function muldrup(
    uint256 x,
    struct DecimalMath.UFixed y
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | uint256 | An unsigned integer.
|`y` | struct DecimalMath.UFixed | A fixed point number.

#### Returns:
| Type | Description |
| --- | --- |
|`An` | unsigned integer.---  
### powd
> Exponentiation (x**n) by squaring of a fixed point number by an integer.
Taken from https://github.com/dapphub/ds-math/blob/master/src/math.sol. Thanks!


#### Declaration
```solidity
  function powd(
    struct DecimalMath.UFixed x,
    uint256 n
  ) internal returns (struct DecimalMath.UFixed)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`x` | struct DecimalMath.UFixed | A fixed point number.
|`n` | uint256 | An unsigned integer.

#### Returns:
| Type | Description |
| --- | --- |
|`An` | unsigned integer.---  


