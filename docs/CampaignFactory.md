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
| factoryWallet | address payable |
| campaignImplementation | address |
| tokenList | address[] |
| campaignTransactionConfigList | string[] |
| approvedcampaignTransactionConfig | mapping(string => bool) |
| campaignTransactionConfig | mapping(string => uint256) |
| categoryCommission | mapping(uint256 => uint256) |
| tokenInList | mapping(address => bool) |
| tokensApproved | mapping(address => bool) |
| factoryRevenue | uint256 |
| campaignRevenueFromCommissions | mapping(uint256 => uint256) |
| campaignRevenueFromFeatures | mapping(uint256 => uint256) |
| deployedCampaigns | struct CampaignFactory.CampaignInfo[] |
| campaignCount | uint256 |
| campaignToOwner | mapping(address => address) |
| campaignToID | mapping(address => uint256) |
| featuredCampaignIsPaused | mapping(uint256 => bool) |
| pausedFeaturedCampaignTimeLeft | mapping(uint256 => uint256) |
| campaignCategories | struct CampaignFactory.CampaignCategory[] |
| categoryCount | uint256 |
| users | struct CampaignFactory.User[] |
| userCount | uint256 |
| userID | mapping(address => uint256) |
| approverTransferRequestCount | mapping(address => uint256) |
| featurePackages | struct CampaignFactory.Featured[] |
| featurePackageCount | uint256 |


## Modifiers

### campaignOwnerOrManager
> Ensures caller is campaign owner or campaign manager

#### Declaration
```solidity
  modifier campaignOwnerOrManager
```


### onlyCampaignOwner
> Ensures caller is campaign owner

#### Declaration
```solidity
  modifier onlyCampaignOwner
```


### campaignExists
> Ensures campaign exists

#### Declaration
```solidity
  modifier campaignExists
```


### campaignIsEnabled
> Ensures campaign is active and approved

#### Declaration
```solidity
  modifier campaignIsEnabled
```


### userIsVerified
> Ensures user is verifed

#### Declaration
```solidity
  modifier userIsVerified
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
    contract Campaign _implementation
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_wallet` | address payable |                      Address where all revenue gets deposited
|`_implementation` | contract Campaign |              Address of base contract to deploy minimal proxies to campaigns
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
### removeToken
>        Removes a token from the list of accepted tokens and tokens in list


#### Declaration
```solidity
  function removeToken(
    uint256 _tokenId,
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
|`_tokenId` | uint256 |      ID of the token
|`_token` | address |   Address of the token
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
### addRole
>        Add an account to the role. Restricted to admins.


#### Declaration
```solidity
  function addRole(
    address _account,
    bytes32 _role
  ) public onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_account` | address | Address of user being assigned role
|`_role` | bytes32 |   Role being assigned
---  
### removeRole
>        Remove an account from the role. Restricted to admins.


#### Declaration
```solidity
  function removeRole(
    address _account,
    bytes32 _role
  ) public onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_account` | address | Address of user whose role is being removed
|`_role` | bytes32 |   Role being removed
---  
### renounceAdmin
> Remove oneself from the admin role.

#### Declaration
```solidity
  function renounceAdmin(
  ) public
```

#### Modifiers:
No modifiers


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
    uint256 _amount,
    contract Campaign _campaign
  ) external onlyCampaignOwner campaignIsEnabled campaignExists
```

#### Modifiers:
| Modifier |
| --- |
| onlyCampaignOwner |
| campaignIsEnabled |
| campaignExists |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_amount` | uint256 |      Amount transfered and collected by factory from campaign request finalization
|`_campaign` | contract Campaign |    Address of campaign instance
---  
### signUp
> Keep track of user addresses. KYC purpose

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
### destroyUser
>        Deletes a user


#### Declaration
```solidity
  function destroyUser(
    uint256 _userId
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
|`_userId` | uint256 |  ID of the user
---  
### createCampaign
>        Deploys and tracks a new campagign


#### Declaration
```solidity
  function createCampaign(
    uint256 _categoryId
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
|`_categoryId` | uint256 |    ID of category campaign deployer specifies
---  
### toggleCampaignApproval
>        Approves or disapproves a campaign. Restricted to campaign managers from factory


#### Declaration
```solidity
  function toggleCampaignApproval(
    uint256 _campaignId,
    bool _approval
  ) external onlyManager campaignExists whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| campaignExists |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignId` | uint256 |    ID of the campaign
|`_approval` | bool |      Indicates if the campaign will be approved or not. Affects campaign listing and transactions
---  
### toggleCampaignActive
>        Temporal campaign deactivation. Restricted to campaign managers or campaign managers from factory


#### Declaration
```solidity
  function toggleCampaignActive(
    uint256 _campaignId,
    bool _active
  ) external campaignOwnerOrManager campaignExists whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignId` | uint256 |    ID of the campaign
|`_active` | bool |      Indicates if the campaign will be active or not.  Affects campaign listing and transactions
---  
### modifyCampaignCategory
>         Modifies a campaign's category.


#### Declaration
```solidity
  function modifyCampaignCategory(
    uint256 _campaignId,
    uint256 _newCategoryId
  ) external campaignOwnerOrManager campaignExists whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignId` | uint256 |      ID of the campaign
|`_newCategoryId` | uint256 |   ID of the category being switched to
---  
### featureCampaign
>        Purchases time for which the specified campaign will be featured. Restricted to


#### Declaration
```solidity
  function featureCampaign(
    uint256 _campaignId,
    uint256 _token
  ) external campaignOwnerOrManager campaignExists campaignIsEnabled userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| campaignIsEnabled |
| userIsVerified |
| whenNotPaused |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignId` | uint256 |    ID of the campaign
|`_token` | uint256 |         Address of token used to purchase feature package
---  
### pauseCampaignFeatured
>        Pauses campaign feature time storing what's left for later use. Restricted to campaign owner or manager


#### Declaration
```solidity
  function pauseCampaignFeatured(
    uint256 _campaignId
  ) external campaignOwnerOrManager campaignExists userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignId` | uint256 |   ID of the campaign
---  
### unpauseCampaignFeatured
>        Resumes campaign feature time


#### Declaration
```solidity
  function unpauseCampaignFeatured(
    uint256 _campaignId
  ) external campaignOwnerOrManager campaignExists userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| userIsVerified |
| whenNotPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaignId` | uint256 |   ID of the campaign
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
### createFeaturePackage
>        Creates a feature package purchased by campaig owners to feature their campaigns


#### Declaration
```solidity
  function createFeaturePackage(
    uint256 _cost,
    uint256 _time
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
|`_cost` | uint256 |        Cost of purchasing this feature package
|`_time` | uint256 |        How long a campaign will be featured for
---  
### modifyFeaturedPackage
>        Modifies details about a feature package


#### Declaration
```solidity
  function modifyFeaturedPackage(
    uint256 _packageId,
    uint256 _cost,
    uint256 _time
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
|`_packageId` | uint256 |   ID of feature package
|`_cost` | uint256 |        Cost of purchasing this feature package
|`_time` | uint256 |        How long a campaign will be featured for
---  
### destroyFeaturedPackage
>        Deletes a feature package


#### Declaration
```solidity
  function destroyFeaturedPackage(
    uint256 _packageId
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
|`_packageId` | uint256 |   ID of feature package
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

### CampaignDeployed
> `Campaign Events`
  


### CampaignApproval

  


### CampaignActiveToggle

  


### CampaignCategoryChange

  


### CampaignFeatured

  


### CampaignFeaturePaused

  


### CampaignFeatureUnpaused

  


### TokenAdded
> `Token Events`
  


### TokenApproval

  


### TokenRemoved

  


### UserAdded
> `User Events`
  


### UserModified

  


### UserApproval

  


### UserRemoved

  


### CategoryAdded
> `Category Events`
  


### CategoryModified

  


### FeaturePackageAdded
> `Feature Package Events`
  


### FeaturePackageModified

  


### FeaturePackageDestroyed

  


