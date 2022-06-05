# CampaignFactory





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| governance | address |
| campaignFactoryAddress | address |
| campaignImplementation | address |
| campaignRewardsImplementation | address |
| campaignVotesImplementation | address |
| campaignRequestsImplementation | address |
| campaignTransactionConfigList | string[] |
| approvedCampaignTransactionConfig | mapping(string => bool) |
| campaignTransactionConfig | mapping(string => uint256) |
| categoryCommission | mapping(uint256 => uint256) |
| factoryRevenue | uint256 |
| campaignRevenueFromCommissions | mapping(address => uint256) |
| campaigns | mapping(contract Campaign => struct CampaignFactory.CampaignInfo) |
| campaignCount | uint256 |
| campaignCategories | struct CampaignFactory.CampaignCategory[] |
| categoryTitleIsTaken | mapping(string => bool) |
| categoryCount | uint256 |
| users | mapping(address => struct CampaignFactory.User) |
| userExists | mapping(address => bool) |
| userCount | uint256 |
| tokens | mapping(address => struct CampaignFactory.Token) |
| trustees | struct CampaignFactory.Trust[] |
| userTrusteeCount | mapping(address => uint256) |
| accountInTransit | mapping(address => bool) |
| accountTransitStartedBy | mapping(address => address) |
| isUserTrustee | mapping(address => mapping(address => bool)) |


## Modifiers

### onlyAdmin
> Ensures caller is owner of contract

#### Declaration
```solidity
  modifier onlyAdmin
```


### campaignOwner
> Ensures caller is campaign owner alone

#### Declaration
```solidity
  modifier campaignOwner
```


### onlyRegisteredCampaigns
> Ensures caller is a registered campaign contract from factory

#### Declaration
```solidity
  modifier onlyRegisteredCampaigns
```



## Functions

### __CampaignFactory_init
>        Contructor


#### Declaration
```solidity
  function __CampaignFactory_init(
    address _governance
  ) public initializer
```

#### Modifiers:
| Modifier |
| --- |
| initializer |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_governance` | address |     Address where all revenue gets deposited
---  
### setCampaignImplementation
>        Updates campaign implementation address


#### Declaration
```solidity
  function setCampaignImplementation(
    contract Campaign _campaignImplementation
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignImplementation` | contract Campaign |  Address of base contract to deploy minimal proxies
---  
### setCampaignRewardImplementation
>        Updates campaign reward implementation address


#### Declaration
```solidity
  function setCampaignRewardImplementation(
    contract CampaignReward _campaignRewardsImplementation
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignRewardsImplementation` | contract CampaignReward |   Address of base contract to deploy minimal proxies
---  
### setCampaignRequestImplementation
>        Updates campaign request implementation address


#### Declaration
```solidity
  function setCampaignRequestImplementation(
    contract CampaignRequest _campaignRequestsImplementation
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignRequestsImplementation` | contract CampaignRequest |   Address of base contract to deploy minimal proxies
---  
### setCampaignVoteImplementation
>        Updates campaign request implementation address


#### Declaration
```solidity
  function setCampaignVoteImplementation(
    contract CampaignVote _campaignVotesImplementation
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignVotesImplementation` | contract CampaignVote |   Address of base contract to deploy minimal proxies
---  
### addFactoryTransactionConfig
>        Adds a new transaction setting


#### Declaration
```solidity
  function addFactoryTransactionConfig(
    string _prop
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_prop` | string |    Setting Key
---  
### setCampaignTransactionConfig
>        Set Factory controlled values dictating how campaign deployments should run


#### Declaration
```solidity
  function setCampaignTransactionConfig(
    string _prop,
    uint256 _value
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_prop` | string |    Setting Key
|`_value` | uint256 |   Setting Value
---  
### setDefaultCommission
>        Sets default commission on all request finalization


#### Declaration
```solidity
  function setDefaultCommission(
    uint256 _numerator,
    uint256 _denominator
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_numerator` | uint256 |    Fraction Fee percentage on request finalization
|`_denominator` | uint256 |  Fraction Fee percentage on request finalization
---  
### setCategoryCommission
>        Sets commission per category basis


#### Declaration
```solidity
  function setCategoryCommission(
    uint256 _categoryId,
    uint256 _numerator,
    uint256 _denominator
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_categoryId` | uint256 |   ID of category
|`_numerator` | uint256 |    Fraction Fee percentage on request finalization in campaign per category `defaultCommission` will be utilized if value is `0`
|`_denominator` | uint256 |  Fraction Fee percentage on request finalization in campaign per category `defaultCommission` will be utilized if value is `0`
---  
### addToken
>        Adds a token that needs approval before being accepted


#### Declaration
```solidity
  function addToken(
    address _token,
    bool _approved,
    string _hashedToken
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_token` | address |       Address of the token
|`_approved` | bool |    Status of token approval
|`_hashedToken` | string | CID reference of the token on IPFS
---  
### toggleAcceptedToken
>        Sets if a token is accepted or not provided it's in the list of token


#### Declaration
```solidity
  function toggleAcceptedToken(
    address _token,
    bool _state
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_token` | address |   Address of the token
|`_state` | bool |   Status of token approval
---  
### canManageCampaigns
>        Checks if a user can manage a campaign. Called but not restricted to external campaign proxies


#### Declaration
```solidity
  function canManageCampaigns(
    address _user
  ) public returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | address |    Address of user
---  
### receiveCampaignCommission
>        Retrieves campaign commission fees. Restricted to campaign owner.


#### Declaration
```solidity
  function receiveCampaignCommission(
    contract Campaign _amount,
    uint256 _campaign
  ) external onlyRegisteredCampaigns
```

#### Modifiers:
| Modifier |
| --- |
| onlyRegisteredCampaigns |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_amount` | contract Campaign |      Amount transfered and collected by factory from campaign request finalization
|`_campaign` | uint256 |    Address of campaign instance
---  
### signUp
>        Keep track of user addresses. sybil resistance purpose


#### Declaration
```solidity
  function signUp(
    string _hashedUser
  ) public whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_hashedUser` | string |  CID reference of the user on IPFS
---  
### userIsVerified
>        Ensures user specified is verified


#### Declaration
```solidity
  function userIsVerified(
    address _user
  ) public returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | address |    Address of user
---  
### initiateUserTransfer
>        Initiates user account transfer proces


#### Declaration
```solidity
  function initiateUserTransfer(
    address _user,
    bool _forSelf
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_user` | address |        Address of user
|`_forSelf` | bool |     Indicates if the transfer is made on behalf of a trustee
---  
### deactivateAccountTransfer
> calls off the user account transfer process

#### Declaration
```solidity
  function deactivateAccountTransfer(
  ) external
```

#### Modifiers:
No modifiers


---  
### addTrustee
>        Trustees are people the user can add to help recover their account in the case they lose access to ther wallets


#### Declaration
```solidity
  function addTrustee(
    address _trustee
  ) external whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_trustee` | address |    Address of the trustee, must be a verified user
---  
### removeTrustee
>        Removes a trustee from users list of trustees


#### Declaration
```solidity
  function removeTrustee(
    uint256 _trusteeId
  ) external whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_trusteeId` | uint256 |    Address of the trustee
---  
### toggleUserApproval
>        Approves or disapproves a user


#### Declaration
```solidity
  function toggleUserApproval(
    address _user,
    bool _approval
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
|`_user` | address |        Address of the user
|`_approval` | bool |    Indicates if the user will be approved or not
---  
### createCampaign
>        Deploys and tracks a new campagign


#### Declaration
```solidity
  function createCampaign(
    uint256 _categoryId,
    bool _privateCampaign,
    string _hashedCampaignInfo
  ) external whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_categoryId` | uint256 |           ID of the category the campaign belongs to
|`_privateCampaign` | bool |             Indicates approval status of the campaign
|`_hashedCampaignInfo` | string |   CID reference of the reward on IPFS
---  
### activateCampaign
>        Activates a campaign. Activating a campaign simply makes the campaign available for listing 
                   on crowdship, events will be stored on thegraph activated or not, Restricted to governance


#### Declaration
```solidity
  function activateCampaign(
    contract Campaign _campaign
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
|`_campaign` | contract Campaign |    Address of the campaign
---  
### toggleCampaignPrivacy
>        Toggles the campaign privacy setting, Restricted to campaign managers


#### Declaration
```solidity
  function toggleCampaignPrivacy(
    contract Campaign _campaign
  ) external campaignOwner whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwner |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaign` | contract Campaign |    Address of the campaign
---  
### modifyCampaignCategory
>         Modifies a campaign's category.


#### Declaration
```solidity
  function modifyCampaignCategory(
    contract Campaign _campaign,
    uint256 _newCategoryId
  ) external campaignOwner whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwner |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaign` | contract Campaign |        Address of the campaign
|`_newCategoryId` | uint256 |   ID of the category being switched to
---  
### createCategory
>        Public implementation of createCategory method


#### Declaration
```solidity
  function createCategory(
    bool _active,
    string _title,
    string _hashedCategory
  ) public onlyAdmin whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_active` | bool |              Indicates if a category is active allowing for campaigns to be assigned to it
|`_title` | string |               Title of the category
|`_hashedCategory` | string |      CID reference of the category on IPFS
---  
### modifyCategory
>        Modifies details about a category


#### Declaration
```solidity
  function modifyCategory(
    uint256 _categoryId,
    bool _active,
    string _title
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
|`_categoryId` | uint256 |         ID of the category
|`_active` | bool |             Indicates if a category is active allowing for campaigns to be assigned to it
|`_title` | string |              Title of the category
---  
### unpauseCampaign
> Unpauses the factory, transactions in the factory resumes per usual

#### Declaration
```solidity
  function unpauseCampaign(
  ) external whenPaused onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| whenPaused |
| onlyAdmin |


---  
### pauseCampaign
> Pauses the factory, halts all transactions in the factory

#### Declaration
```solidity
  function pauseCampaign(
  ) external whenNotPaused onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |
| onlyAdmin |


---  


## Events

### CampaignImplementationUpdated
> `Factory Config Events`
  


### CampaignRewardImplementationUpdated

  


### CampaignRequestImplementationUpdated

  


### CampaignVoteImplementationUpdated

  


### CategoryCommissionUpdated

  


### CampaignDefaultCommissionUpdated

  


### CampaignTransactionConfigUpdated

  


### CampaignDeployed
> `Campaign Events`
  


### CampaignActivation

  


### CampaignPrivacyChange

  


### CampaignCategoryChange

  


### TokenAdded
> `Token Events`
  


### TokenApproval

  


### UserAdded
> `User Events`
  


### UserApproval

  


### TrusteeAdded
> `Trustee Events`
  


### TrusteeRemoved

  


### CategoryAdded
> `Category Events`
  


### CategoryModified

  


