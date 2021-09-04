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
    contract CampaignRewardInterface _campaignReward
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignReward` | contract CampaignRewardInterface |     Campaign reward interface
---  
### _renounceRewards
>        Renounces rewards owned by the specified user


#### Declaration
```solidity
  function _renounceRewards(
    contract CampaignRewardInterface _user
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | contract CampaignRewardInterface |        Address of user who rewards are being renounced
---  
### _transferRewards
>        Transfers rewards from the old owner to a new owner


#### Declaration
```solidity
  function _transferRewards(
    contract CampaignRewardInterface _campaignReward,
    address _oldAddress,
    address _newAddress
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignReward` | contract CampaignRewardInterface |  Campaign reward interface
|`_oldAddress` | address |      Address of previous owner of rewards
|`_newAddress` | address |      Address of new owner rewards are being transferred to
---  


