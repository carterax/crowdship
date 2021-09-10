# CampaignRewards





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| root | address |
| campaignID | uint256 |
| rewards | struct CampaignRewards.Reward[] |
| rewardToRewardRecipientCount | mapping(uint256 => uint256) |
| rewardRecipients | struct CampaignRewards.RewardRecipient[] |
| userRewardCount | mapping(address => uint256) |


## Modifiers

### adminOrFactory
> Ensures caller is factory or campaign owner

#### Declaration
```solidity
  modifier adminOrFactory
```


### campaignIsActive
> Ensures the campaign is set to active by campaign owner and approved by factory

#### Declaration
```solidity
  modifier campaignIsActive
```


### userIsVerified
> Ensures a user is verified

#### Declaration
```solidity
  modifier userIsVerified
```


### onlyRegisteredCampaigns
> Ensures caller is a registered campaign contract from factory

#### Declaration
```solidity
  modifier onlyRegisteredCampaigns
```



## Functions

### __CampaignRewards_init
>        Constructor


#### Declaration
```solidity
  function __CampaignRewards_init(
    contract CampaignFactory _campaignFactory,
    address _campaignOwner,
    uint256 _campaignId
  ) public initializer
```

#### Modifiers:
| Modifier |
| --- |
| initializer |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignFactory` | contract CampaignFactory |     Address of factory
|`_campaignOwner` | address |                Address of campaign owner
|`_campaignId` | uint256 |          ID of campaign reward contract belongs to
---  
### createReward
>        Creates rewards contributors can attain


#### Declaration
```solidity
  function createReward(
    uint256 _value,
    uint256 _deliveryDate,
    uint256 _stock,
    bool _active
  ) external adminOrFactory userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_value` | uint256 |        Reward cost
|`_deliveryDate` | uint256 | Time in which reward will be deliverd to contriutors
|`_stock` | uint256 |        Quantity available for dispatch
|`_active` | bool |       Indicates if contributors can attain the reward
---  
### assignReward
>        Assigns a reward to a user after payment from parent contract Campaign


#### Declaration
```solidity
  function assignReward(
    uint256 _rewardId,
    uint256 _amount,
    address _user
  ) external onlyRegisteredCampaigns userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| onlyRegisteredCampaigns |
| userIsVerified |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardId` | uint256 |     ID of the reward being assigned
|`_amount` | uint256 |       Amount being paid by the user
|`_user` | address |         Address of user reward is being assigned to
---  
### modifyReward
>        Modifies a reward by id


#### Declaration
```solidity
  function modifyReward(
    uint256 _rewardId,
    uint256 _value,
    uint256 _deliveryDate,
    uint256 _stock,
    bool _active
  ) external adminOrFactory userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardId` | uint256 |        Reward unique id
|`_value` | uint256 |           Reward cost
|`_deliveryDate` | uint256 |    Time in which reward will be deliverd to contriutors
|`_stock` | uint256 |           Quantity available for dispatch
|`_active` | bool |          Indicates if contributors can attain the reward
---  
### increaseRewardStock
>        Increases a reward stock count


#### Declaration
```solidity
  function increaseRewardStock(
    uint256 _rewardId,
    uint256 _count
  ) external adminOrFactory userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardId` | uint256 |        Reward unique id
|`_count` | uint256 |           Stock count to increase by
---  
### destroyReward
>        Deletes a reward by id


#### Declaration
```solidity
  function destroyReward(
    uint256 _rewardId
  ) external adminOrFactory userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardId` | uint256 |    Reward unique id
---  
### campaignSentReward
>        Called by the campaign owner to indicate they delivered the reward to the rewardRecipient


#### Declaration
```solidity
  function campaignSentReward(
    uint256 _rewardRecipientId,
    bool _status
  ) external campaignIsActive userIsVerified adminOrFactory
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| adminOrFactory |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardRecipientId` | uint256 |   ID to struct containing reward and user to be rewarded
|`_status` | bool |              Indicates if the delivery was successful or not
---  
### userReceivedCampaignReward
>        Called by a user eligible for rewards to indicate they received their reward


#### Declaration
```solidity
  function userReceivedCampaignReward(
    uint256 _rewardRecipientId
  ) external campaignIsActive userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardRecipientId` | uint256 |  ID to struct containing reward and user to be rewarded
---  
### renounceRewards
>        Renounces rewards owned by the specified user


#### Declaration
```solidity
  function renounceRewards(
    address _user
  ) external onlyRegisteredCampaigns
```

#### Modifiers:
| Modifier |
| --- |
| onlyRegisteredCampaigns |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | address |        Address of user who rewards are being renounced
---  
### transferRewards
>        Transfers rewards from the old owner to a new owner


#### Declaration
```solidity
  function transferRewards(
    address _oldAddress,
    address _newAddress
  ) external onlyRegisteredCampaigns
```

#### Modifiers:
| Modifier |
| --- |
| onlyRegisteredCampaigns |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_oldAddress` | address |      Address of previous owner of rewards
|`_newAddress` | address |      Address of new owner rewards are being transferred to
---  


## Events

### CampaignRewardOwnerSet
> `Initializer Event`
  


### RewardCreated
> `Reward Events`
  


### RewardModified

  


### RewardStockIncreased

  


### RewardDestroyed

  


### RewardRecipientAdded
> `Rward Recipient Events`
  


### RewarderApproval

  


### RewardRecipientApproval

  


