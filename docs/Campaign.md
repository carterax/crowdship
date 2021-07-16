# Campaign





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| goalType | enum Campaign.GOALTYPE |
| campaignState | enum Campaign.CAMPAIGN_STATE |
| campaignFactoryContract | contract CampaignFactoryInterface |
| root | address |
| acceptedToken | address |
| requests | struct Campaign.Request[] |
| requestCount | uint256 |
| rewards | struct Campaign.Reward[] |
| rewardees | struct Campaign.Rewardee[] |
| userHasReward | mapping(address => bool) |
| reviews | struct Campaign.Review[] |
| reviewed | mapping(address => bool) |
| campaignID | uint256 |
| totalCampaignContribution | uint256 |
| minimumContribution | uint256 |
| approversCount | uint256 |
| target | uint256 |
| deadline | uint256 |
| deadlineSetTimes | uint256 |
| reviewCount | uint256 |
| requestOngoing | bool |
| approvers | mapping(address => bool) |
| userTotalContribution | mapping(address => uint256) |
| userBalance | mapping(address => uint256) |


## Modifiers

### onlyFactory


#### Declaration
```solidity
  modifier onlyFactory
```


### adminOrFactory


#### Declaration
```solidity
  modifier adminOrFactory
```


### campaignIsActive


#### Declaration
```solidity
  modifier campaignIsActive
```


### campaignIsNotApproved


#### Declaration
```solidity
  modifier campaignIsNotApproved
```


### userIsVerified


#### Declaration
```solidity
  modifier userIsVerified
```


### canApproveRequest


#### Declaration
```solidity
  modifier canApproveRequest
```


### deadlineIsUp


#### Declaration
```solidity
  modifier deadlineIsUp
```


### targetIsMet


#### Declaration
```solidity
  modifier targetIsMet
```



## Functions

### __Campaign_init
> constructor

#### Declaration
```solidity
  function __Campaign_init(
  ) public initializer
```

#### Modifiers:
| Modifier |
| --- |
| initializer |



### setCampaignDetails
>     Modifies campaign details while it's not approved


#### Declaration
```solidity
  function setCampaignDetails(
    uint256 _target,
    uint256 _minimumContribution,
    uint256 _time,
    uint256 _goalType
  ) external adminOrFactory campaignIsNotApproved nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsNotApproved |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_target` | uint256 |              Contribution target of the campaign
|`_minimumContribution` | uint256 | The minimum amout required to be an approver
|`_time` | uint256 |                How long until the campaign stops receiving contributions
|`_goalType` | uint256 |            Indicates if campaign is fixed or flexible with contributions

### setAcceptedToken
>        Modifies campaign's accepted token provided factory approves it


#### Declaration
```solidity
  function setAcceptedToken(
    address _token
  ) external adminOrFactory campaignIsNotApproved nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsNotApproved |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_token` | address |   Address of token to be used for transactions

### setGoalType
>        Modifies campaign's goal type provided deadline is expired


#### Declaration
```solidity
  function setGoalType(
    uint256 _type
  ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_type` | uint256 |    Indicates if campaign is fixed or flexible with contributions

### extendDeadline
>        Extends campaign contribution deadline


#### Declaration
```solidity
  function extendDeadline(
    uint256 _time
  ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_time` | uint256 |    How long until the campaign stops receiving contributions

### resetDeadlineSetTimes
>        Resets the number of times campaign manager has extended deadlines

#### Declaration
```solidity
  function resetDeadlineSetTimes(
  ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| whenNotPaused |
| nonReentrant |



### createReward
>        Creates rewards contributors can attain


#### Declaration
```solidity
  function createReward(
    uint256 _value,
    uint256 _deliveryDate,
    uint256 _stock,
    bool _active
  ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_value` | uint256 |        Reward cost
|`_deliveryDate` | uint256 | Time in which reward will be deliverd to contriutors
|`_stock` | uint256 |        Quantity available for dispatch
|`_active` | bool |       Indicates if contributors can attain the reward

### modifyReward
>        Modifies a reward by id


#### Declaration
```solidity
  function modifyReward(
    uint256 _id,
    uint256 _value,
    uint256 _deliveryDate,
    uint256 _stock,
    bool _active
  ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_id` | uint256 |              Reward unique id
|`_value` | uint256 |           Reward cost
|`_deliveryDate` | uint256 |    Time in which reward will be deliverd to contriutors
|`_stock` | uint256 |           Quantity available for dispatch
|`_active` | bool |          Indicates if contributors can attain the reward

### destroyReward
>        Deletes a reward by id


#### Declaration
```solidity
  function destroyReward(
    uint256 _rewardId
  ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardId` | uint256 |    Reward unique id

### campaignSentReward


#### Declaration
```solidity
  function campaignSentReward(
  ) external campaignIsActive userIsVerified adminOrFactory whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| adminOrFactory |
| whenNotPaused |
| nonReentrant |



### userReceivedCampaignReward


#### Declaration
```solidity
  function userReceivedCampaignReward(
  ) external campaignIsActive userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### contribute


#### Declaration
```solidity
  function contribute(
  ) external campaignIsActive userIsVerified deadlineIsUp whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| deadlineIsUp |
| whenNotPaused |
| nonReentrant |



### withdrawOwnContribution


#### Declaration
```solidity
  function withdrawOwnContribution(
  ) external campaignIsActive userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### withdrawContributionForUser


#### Declaration
```solidity
  function withdrawContributionForUser(
  ) external onlyFactory nonReentrant whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyFactory |
| nonReentrant |
| whenNotPaused |



### createRequest


#### Declaration
```solidity
  function createRequest(
  ) external adminOrFactory campaignIsActive targetIsMet whenNotPaused userIsVerified nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| targetIsMet |
| whenNotPaused |
| userIsVerified |
| nonReentrant |



### voteOnRequest


#### Declaration
```solidity
  function voteOnRequest(
  ) external campaignIsActive canApproveRequest userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| canApproveRequest |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### finalizeRequest


#### Declaration
```solidity
  function finalizeRequest(
  ) external adminOrFactory campaignIsActive userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### campaignApprovalRequest


#### Declaration
```solidity
  function campaignApprovalRequest(
  ) external onlyAdmin userIsVerified whenPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| userIsVerified |
| whenPaused |
| nonReentrant |



### reviewMode


#### Declaration
```solidity
  function reviewMode(
  ) external adminOrFactory campaignIsActive userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### reviewCampaignPerformance


#### Declaration
```solidity
  function reviewCampaignPerformance(
  ) external userIsVerified campaignIsActive nonReentrant whenPaused
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| campaignIsActive |
| nonReentrant |
| whenPaused |



### markCampaignComplete


#### Declaration
```solidity
  function markCampaignComplete(
  ) external userIsVerified adminOrFactory campaignIsActive whenPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| adminOrFactory |
| campaignIsActive |
| whenPaused |
| nonReentrant |



### unpauseCampaign


#### Declaration
```solidity
  function unpauseCampaign(
  ) external whenPaused onlyFactory nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| whenPaused |
| onlyFactory |
| nonReentrant |



### pauseCampaign


#### Declaration
```solidity
  function pauseCampaign(
  ) external whenNotPaused onlyFactory nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |
| onlyFactory |
| nonReentrant |





## Events

### CampaignDetailsModified
> `Campaign`
  


### CampaignTokenChanged

  


### CampaignGoalTypeChange

  


### CampaignDeadlineExtended

  


### ContributionMade
> `Contribution Events`
  


### ContributionWithdrawn

  


### RequestAdded
> `Request Events`
  


### RequestComplete

  


### RewardCreated
> `Reward Events`
  


### RewardModified

  


### RewardDestroyed

  


### CampaignApprovalRequest

  


### ContributionWithReward
> `Rwardee Events`
  


### Voted
> `Vote Events`
  


### CampaignStateChange
> `Campaign State Events`
  


