# CampaignVote





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| votes | struct CampaignVote.Vote[] |
| voteId | mapping(address => mapping(uint256 => uint256)) |
| campaignID | uint256 |
| campaignFactoryContract | contract ICampaignFactory |
| campaignContract | contract ICampaign |


## Modifiers

### userIsVerified
> Ensures a user is verified

#### Declaration
```solidity
  modifier userIsVerified
```



## Functions

### __CampaignVote_init
>        Constructor


#### Declaration
```solidity
  function __CampaignVote_init(
    contract CampaignFactory _campaignFactory,
    contract Campaign _campaign,
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
|`_campaign` | contract Campaign |            Address of campaign contract
|`_campaignId` | uint256 |          ID of it's campaign contract
---  
### voteOnRequest
>        Approvers only method which approves spending request issued by the campaign manager


#### Declaration
```solidity
  function voteOnRequest(
    uint256 _requestId,
    uint8 _support
  ) external userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |   ID of request being voted on
|`_support` | uint8 |     An integer of 0 for against, 1 for in-favor, and 2 for abstain
---  
### cancelVote
>        Approvers only method which cancels initial vote on a request


#### Declaration
```solidity
  function cancelVote(
    uint256 _requestId
  ) external userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |   ID of request being voted on
---  


## Events

### Voted
> `Vote Events`
  


### VoteCancelled

  


