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
| requests | struct Campaign.Request[] |
| requestCount | uint256 |
| rewards | struct Campaign.Reward[] |
| rewardToRewardRecipientCount | mapping(uint256 => uint256) |
| rewardRecipients | struct Campaign.RewardRecipient[] |
| userRewardCount | mapping(address => uint256) |
| positiveReviewCount | uint256 |
| reviewCount | uint256 |
| reviewed | mapping(address => bool) |
| root | address |
| acceptedToken | address |
| allowContributionAfterTargetIsMet | bool |
| campaignID | uint256 |
| totalCampaignContribution | uint256 |
| minimumContribution | uint256 |
| maximumContribution | uint256 |
| approversCount | uint256 |
| target | uint256 |
| deadline | uint256 |
| deadlineSetTimes | uint256 |
| finalizedRequestCount | uint256 |
| currentRunningRequest | uint256 |
| pauseWithdrawals | bool |
| approvers | mapping(address => bool) |
| userTotalContribution | mapping(address => uint256) |
| percentBase | uint256 |
| percent | uint256 |


## Modifiers

### onlyFactory
> Ensures caller is only factory

#### Declaration
```solidity
  modifier onlyFactory
```


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


### campaignIsNotApproved
> Ensures campaign isn't approved by factory. Applies unless caller is a campaign manager from factory

#### Declaration
```solidity
  modifier campaignIsNotApproved
```


### userIsVerified
> Ensures a user is verified

#### Declaration
```solidity
  modifier userIsVerified
```


### withinDeadline
> Ensures the campaign is within it's deadline, applies only if goal type is fixed

#### Declaration
```solidity
  modifier withinDeadline
```



## Functions

### __Campaign_init
>        Constructor


#### Declaration
```solidity
  function __Campaign_init(
    address _campaignFactory,
    address _root
  ) public initializer
```

#### Modifiers:
| Modifier |
| --- |
| initializer |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignFactory` | address |     Address of factory
|`_root` | address |                Address of campaign owner
---  
### transferCampaignOwnership
>        Transfers campaign ownership from one user to another.


#### Declaration
```solidity
  function transferCampaignOwnership(
    address _newRoot
  ) external onlyAdmin whenNotPaused userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |
| userIsVerified |

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
  ) external onlyFactory nonReentrant whenNotPaused userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| onlyFactory |
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
  ) external adminOrFactory campaignIsNotApproved userIsVerified
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsNotApproved |
| userIsVerified |

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
  ) external adminOrFactory userIsVerified campaignIsActive nonReentrant whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |
| campaignIsActive |
| nonReentrant |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_time` | uint256 |    How long until the campaign stops receiving contributions
---  
### setDeadlineSetTimes
>        Sets the number of times the campaign owner can extended deadlines. Restricted to factory


#### Declaration
```solidity
  function setDeadlineSetTimes(
    uint256 _count
  ) external onlyFactory campaignIsActive whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyFactory |
| campaignIsActive |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_count` | uint256 |   Number of times a campaign owner can extend the deadline
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
  ) external adminOrFactory userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_value` | uint256 |        Reward cost
|`_deliveryDate` | uint256 | Time in which reward will be deliverd to contriutors
|`_stock` | uint256 |        Quantity available for dispatch
|`_active` | bool |       Indicates if contributors can attain the reward
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
  ) external adminOrFactory userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |
| whenNotPaused |

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
  ) external adminOrFactory userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |
| whenNotPaused |

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
  ) external adminOrFactory userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| userIsVerified |
| whenNotPaused |

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
  ) external campaignIsActive userIsVerified adminOrFactory whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| adminOrFactory |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardRecipientId` | uint256 |  ID to struct containing reward and user to be rewarded
|`_status` | bool |      Indicates if the delivery was successful or not
---  
### userReceivedCampaignReward
>        Called by a user eligible for rewards to indicate they received their reward


#### Declaration
```solidity
  function userReceivedCampaignReward(
    uint256 _rewardRecipientId
  ) external campaignIsActive userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_rewardRecipientId` | uint256 |  ID to struct containing reward and user to be rewarded
---  
### contribute
>        Contribute method enables a user become an approver in the campaign


#### Declaration
```solidity
  function contribute(
    address _token,
    uint256 _rewardId,
    bool _withReward
  ) external campaignIsActive userIsVerified withinDeadline whenNotPaused nonReentrant returns (uint256 targetCompletionValue)
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| withinDeadline |
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
    uint256 _amount,
    address payable _wallet
  ) external userIsVerified nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_amount` | uint256 |    Amount requested to be withdrawn from contributions
|`_wallet` | address payable |    Address where amount is delivered
---  
### withdrawContributionForUser
>        Allows withdrawal of balance by factory on behalf of a user. 
                   Cases where users wallet is compromised


#### Declaration
```solidity
  function withdrawContributionForUser(
    address _user,
    uint256 _amount,
    address payable _wallet
  ) external onlyFactory nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyFactory |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | address |      User whose funds are being requested
|`_amount` | uint256 |    Amount requested to be withdrawn from contributions
|`_wallet` | address payable |    Address where amount is delivered
---  
### createRequest
>        Creates a formal request to withdraw funds from user contributions called by the campagn manager or factory
                   Restricted unless target is met and deadline is expired


#### Declaration
```solidity
  function createRequest(
    address payable _recipient,
    uint256 _value,
    uint256 _duration
  ) external adminOrFactory campaignIsActive userIsVerified whenNotPaused withinDeadline
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |
| withinDeadline |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_recipient` | address payable |   Address where requested funds are deposited
|`_value` | uint256 |       Amount being requested by the campaign manager
|`_duration` | uint256 |    Duration until users aren't able to vote on the request
---  
### voidRequest
>        Renders a request void and useless


#### Declaration
```solidity
  function voidRequest(
    uint256 _requestId
  ) external adminOrFactory campaignIsActive userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |   ID of request being voided
---  
### voteOnRequest
>        Approvers only method which approves spending request issued by the campaign manager or factory


#### Declaration
```solidity
  function voteOnRequest(
    uint256 _requestId
  ) external campaignIsActive userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |   ID of request being voted on
---  
### cancelVote
>        Approvers only method which cancels initial vote on a request


#### Declaration
```solidity
  function cancelVote(
    uint256 _requestId
  ) external campaignIsActive userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |   ID of request being voted on
---  
### finalizeRequest
>        Withdrawal method called only when a request receives the right amount votes


#### Declaration
```solidity
  function finalizeRequest(
    uint256 _requestId
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
  ) external adminOrFactory campaignIsActive userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| adminOrFactory |
| campaignIsActive |
| userIsVerified |
| whenNotPaused |


---  
### reviewCampaignPerformance
>        User acknowledgement of review state enabled by the campaign owner


#### Declaration
```solidity
  function reviewCampaignPerformance(
    bool _approval
  ) external userIsVerified campaignIsActive whenPaused
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| campaignIsActive |
| whenPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_approval` | bool |      Indicates user approval of the campaign
---  
### markCampaignComplete
> Called by campaign manager to mark the campaign as complete right after it secured enough reviews from users

#### Declaration
```solidity
  function markCampaignComplete(
  ) external userIsVerified adminOrFactory campaignIsActive whenPaused
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| adminOrFactory |
| campaignIsActive |
| whenPaused |


---  
### reportCampaign
> Called by an approver to report a campaign to factory. Campaign must be in collection or live state

#### Declaration
```solidity
  function reportCampaign(
  ) external userIsVerified campaignIsActive whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| campaignIsActive |
| whenNotPaused |


---  
### setCampaignState
> Changes campaign state

#### Declaration
```solidity
  function setCampaignState(
  ) external onlyFactory
```

#### Modifiers:
| Modifier |
| --- |
| onlyFactory |


---  
### toggleWithdrawalState
>        Pauses and Unpauses withdrawals


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
> `Campaign`
  


### CampaignOwnershipTransferred

  


### CampaignSettingsUpdated

  


### CampaignDeadlineExtended

  


### CampaignReported

  


### CampaignUserDataTransferred
> `Approval Transfer`
  


### ContributionMade
> `Contribution Events`
  


### ContributionWithdrawn

  


### TargetMet

  


### RequestAdded
> `Request Events`
  


### RequestVoided

  


### RequestComplete

  


### RewardCreated
> `Reward Events`
  


### RewardModified

  


### RewardStockIncreased

  


### RewardDestroyed

  


### RewardRecipientAdded
> `Rward Recipient Events`
  


### RewarderApproval

  


### RewardRecipientApproval

  


### Voted
> `Vote Events`
  


### VoteCancelled

  


### CampaignReviewed
> `Review Events`
  


### CampaignStateChange
> `Campaign State Events`
  


