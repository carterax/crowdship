# CampaignFactory





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| MANAGE_CATEGORIES | bytes32 |
| MANAGE_CAMPAIGNS | bytes32 |
| MANAGE_USERS | bytes32 |
| root | address |
| campaignFactoryAddress | address |
| factoryWallet | address payable |
| campaignImplementation | address |
| campaignRewardsImplementation | address |
| campaignVotesImplementation | address |
| campaignRequestsImplementation | address |
| campaignTransactionConfigList | string[] |
| approvedCampaignTransactionConfig | mapping(string => bool) |
| campaignTransactionConfig | mapping(string => uint256) |
| categoryCommission | mapping(uint256 => uint256) |
| tokenInList | mapping(address => bool) |
| tokensApproved | mapping(address => bool) |
| factoryRevenue | uint256 |
| campaignRevenueFromCommissions | mapping(uint256 => uint256) |
| deployedCampaigns | struct CampaignFactory.CampaignInfo[] |
| campaignCount | uint256 |
| campaignToOwner | mapping(address => address) |
| campaignToID | mapping(address => uint256) |
| campaignCategories | struct CampaignFactory.CampaignCategory[] |
| categoryCount | uint256 |
| users | struct CampaignFactory.User[] |
| userCount | uint256 |
| userID | mapping(address => uint256) |
| trustees | struct CampaignFactory.Trust[] |
| userTrusteeCount | mapping(address => uint256) |
| isUserTrustee | mapping(address => mapping(address => bool)) |


## Modifiers

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
    address payable _wallet
  ) public initializer
```

#### Modifiers:
| Modifier |
| --- |
| initializer |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_wallet` | address payable |     Address where all revenue gets deposited
---  
### setFactoryConfig
>        Set Factory controlled values dictating how campaigns should run


#### Declaration
```solidity
  function setFactoryConfig(
    address payable _wallet,
    contract Campaign _campaignImplementation,
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
|`_wallet` | address payable |                          Address where all revenue gets deposited
|`_campaignImplementation` | contract Campaign |          Address of base contract to deploy minimal proxies to campaigns
|`_campaignRewardsImplementation` | contract CampaignReward |   Address of base contract to deploy minimal proxies to campaign rewards
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
    address _token
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_token` | address |  Address of the token
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
|`_state` | bool |   Indicates if the token is approved or not
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
> Keep track of user addresses. sybil resistance purpose

#### Declaration
```solidity
  function signUp(
  ) public whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |


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
    uint256 _userId,
    bool _approval
  ) external onlyManager whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_userId` | uint256 |      ID of the user
|`_approval` | bool |    Indicates if the user will be approved or not
---  
### createCampaign
>        Deploys and tracks a new campagign


#### Declaration
```solidity
  function createCampaign(
    uint256 _categoryId
  ) external whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_categoryId` | uint256 |    ID of category campaign deployer specifies
---  
### toggleCampaignApproval
>        Approves or disapproves a campaign. Restricted to campaign managers


#### Declaration
```solidity
  function toggleCampaignApproval(
    uint256 _campaignId,
    bool _approval
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
|`_campaignId` | uint256 |    ID of the campaign
|`_approval` | bool |      Indicates if the campaign will be approved or not. Affects campaign listing and transactions
---  
### modifyCampaignCategory
>         Modifies a campaign's category.


#### Declaration
```solidity
  function modifyCampaignCategory(
    uint256 _campaignId,
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
|`_campaignId` | uint256 |      ID of the campaign
|`_newCategoryId` | uint256 |   ID of the category being switched to
---  
### createCategory
>        Creates a category


#### Declaration
```solidity
  function createCategory(
    bool _active
  ) external onlyManager whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_active` | bool |   Indicates if a category is active allowing for campaigns to be assigned to it
---  
### modifyCategory
>        Modifies details about a category


#### Declaration
```solidity
  function modifyCategory(
    uint256 _categoryId,
    bool _active
  ) external onlyManager whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_categoryId` | uint256 |   ID of the category
|`_active` | bool |       Indicates if a category is active allowing for campaigns to be assigned to it
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

### FactoryConfigUpdated
> `Factory Config Events`
  


### CategoryCommissionUpdated

  


### CampaignDefaultCommissionUpdated

  


### CampaignTransactionConfigUpdated

  


### CampaignDeployed
> `Campaign Events`
  


### CampaignApproval

  


### CampaignActiveToggle

  


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

  


