# CampaignRequest





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| requests | struct CampaignRequest.Request[] |
| requestCount | uint256 |
| finalizedRequestCount | uint256 |
| currentRunningRequest | uint256 |
| campaignID | uint256 |
| campaignFactoryContract | contract ICampaignFactory |
| campaignContract | contract ICampaign |


## Modifiers

### onlyAdmin
> Ensures caller is campaign owner

#### Declaration
```solidity
  modifier onlyAdmin
```


### userIsVerified
> Ensures caller is a verified user

#### Declaration
```solidity
  modifier userIsVerified
```



## Functions

### __CampaignRequest_init
>        Constructor


#### Declaration
```solidity
  function __CampaignRequest_init(
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
### createRequest
>        Creates a formal request to withdraw funds from user contributions called by the campagn manager
                   Restricted unless target is met and deadline is expired


#### Declaration
```solidity
  function createRequest(
    address payable _recipient,
    uint256 _value,
    uint256 _duration
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
|`_requestId` | uint256 |   ID of request being voided
---  
### signRequestVote
>        Finalizes vote on a request, called only from voting contract


#### Declaration
```solidity
  function signRequestVote(
    uint256 _requestId,
    uint256 _support
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |   ID of request being finalized
|`_support` | uint256 |     An integer of 0 for against, 1 for in-favor, and 2 for abstain
---  
### cancelVoteSignature
>        Finalizes vote cancellation, called only from the voting contract


#### Declaration
```solidity
  function cancelVoteSignature(
    uint256 _requestId
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |   ID of request whose vote is being cancelled
---  
### signRequestFinalization
>        Request finalization called only from the campaign contract


#### Declaration
```solidity
  function signRequestFinalization(
    uint256 _requestId
  ) external whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_requestId` | uint256 |      ID of request whose withdrawal is being finalized
---  


## Events

### RequestAdded
> `Request Events`
  


### RequestVoided

  


