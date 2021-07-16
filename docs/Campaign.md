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
No description


#### Declaration
```solidity
  modifier onlyFactory
```


### adminOrFactory
No description


#### Declaration
```solidity
  modifier adminOrFactory
```


### campaignIsActive
No description


#### Declaration
```solidity
  modifier campaignIsActive
```


### campaignIsNotApproved
No description


#### Declaration
```solidity
  modifier campaignIsNotApproved
```


### userIsVerified
No description


#### Declaration
```solidity
  modifier userIsVerified
```


### canApproveRequest
No description


#### Declaration
```solidity
  modifier canApproveRequest
```


### deadlineIsUp
No description


#### Declaration
```solidity
  modifier deadlineIsUp
```


### targetIsMet
No description


#### Declaration
```solidity
  modifier targetIsMet
```



## Functions

### __Campaign_init
No description
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
No description
>        Modifies campaign details while it's not approved


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
No description
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
No description
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
No description
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
No description
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
No description
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
No description
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
No description
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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description


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
No description
> `Campaign`
  


### CampaignTokenChanged
No description

  


### CampaignGoalTypeChange
No description

  


### CampaignDeadlineExtended
No description

  


### ContributionMade
No description
> `Contribution Events`
  


### ContributionWithdrawn
No description

  


### RequestAdded
No description
> `Request Events`
  


### RequestComplete
No description

  


### RewardCreated
No description
> `Reward Events`
  


### RewardModified
No description

  


### RewardDestroyed
No description

  


### CampaignApprovalRequest
No description

  


### ContributionWithReward
No description
> `Rwardee Events`
  


### Voted
No description
> `Vote Events`
  


### CampaignStateChange
No description
> `Campaign State Events`
  


