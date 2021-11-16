# CampaignRewardLib





## Contents
<!-- START doctoc -->
<!-- END doctoc -->




## Functions

### _assignReward
>        Assigns a reward to the user


#### Declaration
```solidity
  function _assignReward(
    contract ICampaignReward _campaignReward
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignReward` | contract ICampaignReward |     Campaign reward interface
---  
### _renounceRewards
>        Renounces rewards owned by the specified user


#### Declaration
```solidity
  function _renounceRewards(
    contract ICampaignReward _user
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | contract ICampaignReward |        Address of user who rewards are being renounced
---  
### _transferRewards
>        Transfers rewards from the old owner to a new owner


#### Declaration
```solidity
  function _transferRewards(
    contract ICampaignReward _campaignReward,
    address _oldAddress,
    address _newAddress
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignReward` | contract ICampaignReward |  Campaign reward interface
|`_oldAddress` | address |      Address of previous owner of rewards
|`_newAddress` | address |      Address of new owner rewards are being transferred to
---  


