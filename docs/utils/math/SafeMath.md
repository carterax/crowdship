# SafeMath



> Wrappers over Solidity's arithmetic operations with added overflow
checks.

Arithmetic operations in Solidity wrap on overflow. This can easily result
in bugs, because programmers usually assume that an overflow raises an
error, which is the standard behavior in high level programming languages.
`SafeMath` restores this intuition by reverting the transaction when an
operation overflows.

Using this library instead of the unchecked operations eliminates an entire
class of bugs, so it's recommended to use it always.

## Contents
<!-- START doctoc -->
<!-- END doctoc -->




## Functions

### add
> Returns the addition of two unsigned integers, reverting on
overflow.

Counterpart to Solidity's `+` operator.

Requirements:

- Addition cannot overflow.

#### Declaration
```solidity
  function add(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers


---  
### sub
> Returns the subtraction of two unsigned integers, reverting on
overflow (when the result is negative).

Counterpart to Solidity's `-` operator.

Requirements:

- Subtraction cannot overflow.

#### Declaration
```solidity
  function sub(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers


---  
### sub
> Returns the subtraction of two unsigned integers, reverting with custom message on
overflow (when the result is negative).

Counterpart to Solidity's `-` operator.

Requirements:

- Subtraction cannot overflow.

#### Declaration
```solidity
  function sub(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers


---  
### mul
> Returns the multiplication of two unsigned integers, reverting on
overflow.

Counterpart to Solidity's `*` operator.

Requirements:

- Multiplication cannot overflow.

#### Declaration
```solidity
  function mul(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers


---  
### div
> Returns the integer division of two unsigned integers. Reverts on
division by zero. The result is rounded towards zero.

Counterpart to Solidity's `/` operator. Note: this function uses a
`revert` opcode (which leaves remaining gas untouched) while Solidity
uses an invalid opcode to revert (consuming all remaining gas).

Requirements:

- The divisor cannot be zero.

#### Declaration
```solidity
  function div(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers


---  
### div
> Returns the integer division of two unsigned integers. Reverts with custom message on
division by zero. The result is rounded towards zero.

Counterpart to Solidity's `/` operator. Note: this function uses a
`revert` opcode (which leaves remaining gas untouched) while Solidity
uses an invalid opcode to revert (consuming all remaining gas).

Requirements:

- The divisor cannot be zero.

#### Declaration
```solidity
  function div(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers


---  
### mod
> Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
Reverts when dividing by zero.

Counterpart to Solidity's `%` operator. This function uses a `revert`
opcode (which leaves remaining gas untouched) while Solidity uses an
invalid opcode to revert (consuming all remaining gas).

Requirements:

- The divisor cannot be zero.

#### Declaration
```solidity
  function mod(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers


---  
### mod
> Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
Reverts with custom message when dividing by zero.

Counterpart to Solidity's `%` operator. This function uses a `revert`
opcode (which leaves remaining gas untouched) while Solidity uses an
invalid opcode to revert (consuming all remaining gas).

Requirements:

- The divisor cannot be zero.

#### Declaration
```solidity
  function mod(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers


---  


