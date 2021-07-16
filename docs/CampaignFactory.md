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
| userCampaignHistory | struct CampaignFactory.UserCampaignHistory[] |
| featurePackages | struct CampaignFactory.Featured[] |
| featurePackageCount | uint256 |


## Modifiers

### campaignOwnerOrManager
No description


#### Declaration
```solidity
  modifier campaignOwnerOrManager
```


### onlyCampaignOwner
No description


#### Declaration
```solidity
  modifier onlyCampaignOwner
```


### campaignExists
No description


#### Declaration
```solidity
  modifier campaignExists
```


### campaignIsEnabled
No description


#### Declaration
```solidity
  modifier campaignIsEnabled
```


### userOrManager
No description


#### Declaration
```solidity
  modifier userOrManager
```


### userIsVerified
No description


#### Declaration
```solidity
  modifier userIsVerified
```



## Functions

### __CampaignFactory_init
No description
> Add `root` to the admin role as a member.

#### Declaration
```solidity
  function __CampaignFactory_init(
  ) public initializer
```

#### Modifiers:
| Modifier |
| --- |
| initializer |



### setFactoryWallet
No description


#### Declaration
```solidity
  function setFactoryWallet(
  ) external onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |



### receiveCampaignCommission
No description


#### Declaration
```solidity
  function receiveCampaignCommission(
  ) external onlyCampaignOwner campaignIsEnabled campaignExists nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyCampaignOwner |
| campaignIsEnabled |
| campaignExists |
| nonReentrant |



### setCampaignImplementationAddress
No description


#### Declaration
```solidity
  function setCampaignImplementationAddress(
  ) external onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |



### setDefaultCommission
No description


#### Declaration
```solidity
  function setDefaultCommission(
  ) external onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |



### setCategoryCommission
No description


#### Declaration
```solidity
  function setCategoryCommission(
  ) external onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |



### addToken
No description


#### Declaration
```solidity
  function addToken(
  ) external onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |



### toggleAcceptedToken
No description


#### Declaration
```solidity
  function toggleAcceptedToken(
  ) external onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |



### addRole
No description
> Add an account to the manager role. Restricted to admins.

#### Declaration
```solidity
  function addRole(
  ) public onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |



### removeRole
No description
> Remove an account from the manager role. Restricted to admins.

#### Declaration
```solidity
  function removeRole(
  ) public onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| nonReentrant |



### renounceAdmin
No description
> Remove oneself from the admin role.

#### Declaration
```solidity
  function renounceAdmin(
  ) public
```

#### Modifiers:
No modifiers



### canManageCampaigns
No description


#### Declaration
```solidity
  function canManageCampaigns(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### signUp
No description


#### Declaration
```solidity
  function signUp(
  ) public whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |
| nonReentrant |



### toggleUserApproval
No description


#### Declaration
```solidity
  function toggleUserApproval(
  ) external onlyManager whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| whenNotPaused |
| nonReentrant |



### destroyUser
No description


#### Declaration
```solidity
  function destroyUser(
  ) external onlyManager whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| whenNotPaused |
| nonReentrant |



### addCampaignToUserHistory
No description


#### Declaration
```solidity
  function addCampaignToUserHistory(
  ) external campaignExists whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignExists |
| whenNotPaused |
| nonReentrant |



### createCampaign
No description


#### Declaration
```solidity
  function createCampaign(
  ) external userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### toggleCampaignApproval
No description


#### Declaration
```solidity
  function toggleCampaignApproval(
  ) external onlyManager campaignExists whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| campaignExists |
| whenNotPaused |
| nonReentrant |



### toggleCampaignActive
No description


#### Declaration
```solidity
  function toggleCampaignActive(
  ) external campaignOwnerOrManager campaignExists whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| whenNotPaused |
| nonReentrant |



### modifyCampaignCategory
No description


#### Declaration
```solidity
  function modifyCampaignCategory(
  ) external campaignOwnerOrManager campaignExists whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| campaignOwnerOrManager |
| campaignExists |
| whenNotPaused |
| nonReentrant |



### featureCampaign
No description


#### Declaration
```solidity
  function featureCampaign(
  ) external onlyCampaignOwner campaignExists campaignIsEnabled userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyCampaignOwner |
| campaignExists |
| campaignIsEnabled |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### pauseCampaignFeatured
No description


#### Declaration
```solidity
  function pauseCampaignFeatured(
  ) external onlyCampaignOwner campaignExists userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyCampaignOwner |
| campaignExists |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### unpauseCampaignFeatured
No description


#### Declaration
```solidity
  function unpauseCampaignFeatured(
  ) external onlyCampaignOwner campaignExists userIsVerified whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyCampaignOwner |
| campaignExists |
| userIsVerified |
| whenNotPaused |
| nonReentrant |



### destroyCampaign
No description


#### Declaration
```solidity
  function destroyCampaign(
  ) external onlyManager campaignExists whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| campaignExists |
| whenNotPaused |
| nonReentrant |



### createCategory
No description


#### Declaration
```solidity
  function createCategory(
  ) external onlyManager whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| whenNotPaused |
| nonReentrant |



### modifyCategory
No description


#### Declaration
```solidity
  function modifyCategory(
  ) external onlyManager whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| whenNotPaused |
| nonReentrant |



### destroyCategory
No description


#### Declaration
```solidity
  function destroyCategory(
  ) external onlyManager whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyManager |
| whenNotPaused |
| nonReentrant |



### createFeaturePackage
No description


#### Declaration
```solidity
  function createFeaturePackage(
  ) external onlyAdmin whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |
| nonReentrant |



### modifyFeaturedPackage
No description


#### Declaration
```solidity
  function modifyFeaturedPackage(
  ) external onlyAdmin whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |
| nonReentrant |



### destroyFeaturedPackage
No description


#### Declaration
```solidity
  function destroyFeaturedPackage(
  ) external onlyAdmin whenNotPaused nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlyAdmin |
| whenNotPaused |
| nonReentrant |



### unpauseCampaign
No description


#### Declaration
```solidity
  function unpauseCampaign(
  ) external whenPaused onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| whenPaused |
| onlyAdmin |
| nonReentrant |



### pauseCampaign
No description


#### Declaration
```solidity
  function pauseCampaign(
  ) external whenNotPaused onlyAdmin nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |
| onlyAdmin |
| nonReentrant |





## Events

### CampaignDeployed
No description
> `Campaign Events`
  


### CampaignDestroyed
No description

  


### CampaignApproval
No description

  


### CampaignActiveToggle
No description

  


### CampaignCategoryChange
No description

  


### CampaignFeatured
No description

  


### CampaignFeaturePaused
No description

  


### CampaignFeatureUnpaused
No description

  


### UserAdded
No description
> `User Events`
  


### UserModified
No description

  


### UserApproval
No description

  


### UserJoinedCampaign
No description

  


### UserRemoved
No description

  


### CategoryAdded
No description
> `Category Events`
  


### CategoryModified
No description

  


### CategoryDestroyed
No description

  


### FeaturePackageAdded
No description
> `Feature Package Events`
  


### FeaturePackageModified
No description

  


### FeaturePackageDestroyed
No description

  


