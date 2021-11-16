# Campaign





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| MANAGER | bytes32 |
| goalType | enum Campaign.GOALTYPE |
| campaignState | enum Campaign.CAMPAIGN_STATE |
| campaignFactoryContract | contract ICampaignFactory |
| campaignRewardContract | contract ICampaignReward |
| campaignRequestContract | contract ICampaignRequest |
| campaignVoteContract | contract ICampaignVote |
| contributions | struct Campaign.Contribution[] |
| contributionId | mapping(address => uint256) |
| reviewCount | uint256 |
| reviewed | mapping(address => bool) |
| root | address |
| acceptedToken | address |
| allowContributionAfterTargetIsMet | bool |
| withdrawalsPaused | bool |
| percentBase | uint8 |
| percent | uint256 |
| campaignID | uint256 |
| totalCampaignContribution | uint256 |
| campaignBalance | uint256 |
| minimumContribution | uint256 |
| approversCount | uint256 |
| target | uint256 |
| deadline | uint256 |
| deadlineSetTimes | uint256 |
| reportCount | uint256 |
| approvers | mapping(address => bool) |
| reported | mapping(address => bool) |
| transferAttemptCount | mapping(address => uint256) |
| timeUntilNextTransferConfirmation | mapping(address => uint256) |


## Modifiers

### onlyFactory
> Ensures caller is only factory, works only if campaign is approved

#### Declaration
```solidity
  modifier onlyFactory
```


### userIsVerified
> Ensures a user is verified

#### Declaration
```solidity
  modifier userIsVerified
```



## Functions

### __Campaign_init
>        Constructor


#### Declaration
```solidity
  function __Campaign_init(
    contract CampaignFactory _campaignFactory,
    contract CampaignReward _campaignRewards,
    contract CampaignRequest _campaignRequests,
    contract CampaignVote _campaignVotes,
    address _root,
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
|`_campaignRewards` | contract CampaignReward |     Address of campaign reward contract
|`_campaignRequests` | contract CampaignRequest |    Address of campaign request contract
|`_campaignVotes` | contract CampaignVote |       Address of campaign vote contract
|`_root` | address |                Address of campaign owner
|`_campaignId` | uint256 |          ID of the campaign from campaign factory
---  
### isCampaignAdmin
>        Checks if a provided address is a campaign admin


#### Declaration
```solidity
  function isCampaignAdmin(
    address _user
  ) external returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | address |     Address of the user
---  
### getCampaignGoalType
> Returns the campaigns funding goal type

#### Declaration
```solidity
  function getCampaignGoalType(
  ) external returns (enum Campaign.GOALTYPE)
```

#### Modifiers:
No modifiers


---  
### getCampaignState
>        Returns a campaign state by a provided index


#### Declaration
```solidity
  function getCampaignState(
    uint256 _state
  ) external returns (enum Campaign.CAMPAIGN_STATE)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_state` | uint256 |     Integer representing a state in the campaign
---  
### transferCampaignOwnership
>        Transfers campaign ownership from one user to another.


#### Declaration
```solidity
  function transferCampaignOwnership(
    address _newRoot
  ) external onlyAdmin whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_newRoot` | address |    Address of the user campaign ownership is being transfered to
---  
### transferCampaignUserData
>        Transfers user data in the campaign to another verifed user


#### Declaration
```solidity
  function transferCampaignUserData(
    address _oldAddress,
    address _newAddress
  ) external nonReentrant whenNotPaused userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| nonReentrant |
| whenNotPaused |
| userIsVerified |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_oldAddress` | address |    Address of the user transferring
|`_newAddress` | address |    Address of the user being transferred to
---  
### setCampaignSettings
>         Modifies campaign details while it's not approved


#### Declaration
```solidity
  function setCampaignSettings(
    uint256 _target,
    uint256 _minimumContribution,
    uint256 _duration,
    uint256 _goalType,
    address _token,
    bool _allowContributionAfterTargetIsMet
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_target` | uint256 |                              Contribution target of the campaign
|`_minimumContribution` | uint256 |                 The minimum amout required to be an approver
|`_duration` | uint256 |                            How long until the campaign stops receiving contributions
|`_goalType` | uint256 |                            If flexible the campaign owner is able to create requests if targe isn't met, fixed opposite
|`_token` | address |                               Address of token to be used for transactions by default
|`_allowContributionAfterTargetIsMet` | bool |   Indicates if the campaign can receive contributions after duration expires
---  
### extendDeadline
>        Extends campaign contribution deadline


#### Declaration
```solidity
  function extendDeadline(
    uint256 _time
  ) external onlyAdmin nonReentrant whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_time` | uint256 |    How long until the campaign stops receiving contributions
---  
### setDeadlineSetTimes
>        Sets the number of times the campaign owner can extended deadlines.


#### Declaration
```solidity
  function setDeadlineSetTimes(
    uint8 _count
  ) external onlyAdmin whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_count` | uint8 |   Number of times a campaign owner can extend the deadline
---  
### contribute
>        Contribute method enables a user become an approver in the campaign


#### Declaration
```solidity
  function contribute(
    address _token,
    uint256 _rewardId,
    bool _withReward
  ) external userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_token` | address |       Address of token to be used for transactions by default
|`_rewardId` | uint256 |    Reward unique id
|`_withReward` | bool |  Indicates if the user wants a reward alongside their contribution
---  
### withdrawOwnContribution
>        Allows withdrawal of contribution by a user, works if campaign target isn't met


#### Declaration
```solidity
  function withdrawOwnContribution(
    address payable _wallet
  ) external nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_wallet` | address payable |    Address where amount is delivered
---  
### userContributionLoss
>        Used to measure user funds left after request finalizations


#### Declaration
```solidity
  function userContributionLoss(
    address _user
  ) public returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | address |    Address of user check is carried out on
---  
### finalizeRequest
>        Withdrawal method called only when a request receives the right amount votes


#### Declaration
```solidity
  function finalizeRequest(
    uint256 _requestId
  ) external onlyAdmin whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |      ID of request being withdrawn
---  
### reviewMode
> Pauses the campaign and switches `campaignState` to `REVIEW` indicating it's ready to be reviewd by it's approvers after the campaign is over

#### Declaration
```solidity
  function reviewMode(
  ) external onlyAdmin whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |


---  
### reviewCampaignPerformance
> User acknowledgement of review state enabled by the campaign owner

#### Declaration
```solidity
  function reviewCampaignPerformance(
  ) external userIsVerified whenPaused
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| whenPaused |


---  
### markCampaignComplete
> Called by campaign manager to mark the campaign as complete right after it secured enough reviews from users

#### Declaration
```solidity
  function markCampaignComplete(
  ) external onlyAdmin whenPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenPaused |


---  
### reportCampaign
> Called by an approver to report a campaign. Campaign must be in collection or live state

#### Declaration
```solidity
  function reportCampaign(
  ) external userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| whenNotPaused |


---  
### toggleWithdrawalState
>        Pauses or Unpauses withdrawals depending on state passed in argument


#### Declaration
```solidity
  function toggleWithdrawalState(
    bool _state
  ) external onlyFactory
```

#### Modifiers:
| Modifier |
| --- |
| onlyFactory |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_state` | bool |      Indicates pause or unpause state
---  
### unpauseCampaign
> Unpauses the campaign, transactions in the campaign resume per usual

#### Declaration
```solidity
  function unpauseCampaign(
  ) external whenPaused onlyFactory
```

#### Modifiers:
| Modifier |
| --- |
| whenPaused |
| onlyFactory |


---  
### pauseCampaign
> Pauses the campaign, it halts all transactions in the campaign

#### Declaration
```solidity
  function pauseCampaign(
  ) external whenNotPaused onlyFactory
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |
| onlyFactory |


---  


## Events

### CampaignOwnerSet
> `Initializer Event`
  


### CampaignOwnershipTransferred
> `Campaign Config Events`
  


### CampaignSettingsUpdated

  


### CampaignDeadlineExtended

  


### DeadlineThresholdExtended

  


### CampaignUserDataTransferred
> `Approval Transfer`
  


### ContributionMade
> `Contribution Events`
  


### ContributionWithdrawn

  


### RequestComplete
> `Request Event`
  


### CampaignReviewed
> `Review Events`
  


### CampaignReported

  


### CampaignStateChange
> `Campaign State Events`
  


