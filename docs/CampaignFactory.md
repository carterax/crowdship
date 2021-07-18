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
| defaultCommission | uint256 |
| deadlineStrikesAllowed | uint256 |
| minimumContributionAllowed | uint256 |
| maximumContributionAllowed | uint256 |
| maxDeadline | uint256 |
| minDeadline | uint256 |
| factoryRevenue | uint256 |
| tokenList | address[] |
| categoryCommission | mapping(uint256 => uint256) |
| tokenInList | mapping(address => bool) |
| tokensApproved | mapping(address => bool) |
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
### setFactorySettings
>        Factory controlled values dictating how campaigns should run


#### Declaration
```solidity
  function setFactorySettings(
    address payable _wallet,
    contract Campaign _implementation,
    uint256 _commission,
    uint256 _deadlineStrikesAllowed,
    uint256 _maxDeadline,
    uint256 _minDeadline,
    uint256 _minimumContributionAllowed,
    uint256 _maximumContributionAllowed
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
|`_commission` | uint256 |                  Default fee percentage on request finalization in campaign
|`_deadlineStrikesAllowed` | uint256 |      Number of times campaign owner is allowed to extend deadline
|`_maxDeadline` | uint256 |                 Maximum time allowed to extend the deadline by
|`_minDeadline` | uint256 |                 Minimum time allowed to extend the deadline by
|`_minimumContributionAllowed` | uint256 |  Minimum allowed contribution in campaigns
|`_maximumContributionAllowed` | uint256 |  Maximum allowed contribution in campaigns
---  
### setCategoryCommission
>        Adds commission per category basis


#### Declaration
```solidity
  function setCategoryCommission(
    uint256 _categoryId,
    uint256 _commission
  ) external onlyAdmin
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_categoryId` | uint256 |  ID of category
|`_commission` | uint256 |  Fee percentage on request finalization in campaign per category `defaultCommission` will be utilized if value is `0`
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
>        Approves or disapproves a campaign. Restricted to campaign managers


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
>        Approves or disapproves a campaign. Restricted to campaign managers


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
### modifyCampaignDetails
>         External call to campaign instance modifying it's settings wether it's approved or not
                    Restricted to Campaign Managers


#### Declaration
```solidity
  function modifyCampaignDetails(
    contract Campaign _target,
    uint256 _minimumContribution,
    uint256 _duration,
    uint256 _goalType,
    uint256 _token
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
|`_target` | contract Campaign |              Contribution target of the campaign
|`_minimumContribution` | uint256 | The minimum amout required to be an approver
|`_duration` | uint256 |            How long until the campaign stops receiving contributions
|`_goalType` | uint256 |            Indicates if campaign is fixed or flexible with contributions
|`_token` | uint256 |               Address of token to be used for transactions by default
---  
### modifyCampaignCategory


#### Declaration
```solidity
  function modifyCampaignCategory(
  ) external campaignOwnerOrManager campaignExists whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| whenNotPaused |


---  
### campaignApprovalRequest
>        Called by a campaign owner seeking to be approved and ready to receive contributions


#### Declaration
```solidity
  function campaignApprovalRequest(
    address _campaign
  ) external onlyCampaignOwner campaignExists userIsVerified whenPaused
```

#### Modifiers:
| Modifier |
| --- |
| onlyCampaignOwner |
| campaignExists |
| userIsVerified |
| whenPaused |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_campaign` | address |    Address of campaign instance
---  
### featureCampaign
>        Called by a campaign owner seeking to be approved and ready to receive contributions


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
|`_campaignId` | uint256 |    Address of campaign instance
|`_token` | uint256 |         Address of token used to purchase feature package
---  
### pauseCampaignFeatured


#### Declaration
```solidity
  function pauseCampaignFeatured(
  ) external campaignOwnerOrManager campaignExists userIsVerified whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| userIsVerified |
| whenNotPaused |


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
|`_campaignId` | uint256 |   ID of campaign
---  
### destroyCampaign
>        Deletes a campaign


#### Declaration
```solidity
  function destroyCampaign(
    uint256 _campaignId
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
|`_campaignId` | uint256 |   ID of campaign
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
### destroyCategory
>        Deletes a category


#### Declaration
```solidity
  function destroyCategory(
    uint256 _categoryId
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
|`_categoryId` | uint256 |   ID of category
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
  


### CampaignDestroyed

  


### CampaignApproval

  


### CampaignActiveToggle

  


### CampaignCategoryChange

  


### CampaignFeatured

  


### CampaignFeaturePaused

  


### CampaignFeatureUnpaused

  


### CampaignApprovalRequest

  


### UserAdded
> `User Events`
  


### UserModified

  


### UserApproval

  


### UserRemoved

  


### CategoryAdded
> `Category Events`
  


### CategoryModified

  


### CategoryDestroyed

  


### FeaturePackageAdded
> `Feature Package Events`
  


### FeaturePackageModified

  


### FeaturePackageDestroyed

  


