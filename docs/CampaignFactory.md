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


#### Declaration
```solidity
  modifier campaignOwnerOrManager
```


### onlyCampaignOwner


#### Declaration
```solidity
  modifier onlyCampaignOwner
```


### campaignExists


#### Declaration
```solidity
  modifier campaignExists
```


### campaignIsEnabled


#### Declaration
```solidity
  modifier campaignIsEnabled
```


### userOrManager


#### Declaration
```solidity
  modifier userOrManager
```


### userIsVerified


#### Declaration
```solidity
  modifier userIsVerified
```



## Functions

### __CampaignFactory_init
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
> Remove oneself from the admin role.

#### Declaration
```solidity
  function renounceAdmin(
  ) public
```

#### Modifiers:
No modifiers



### canManageCampaigns


#### Declaration
```solidity
  function canManageCampaigns(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### signUp


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
> `Campaign Events`
  


### CampaignDestroyed

  


### CampaignApproval

  


### CampaignActiveToggle

  


### CampaignCategoryChange

  


### CampaignFeatured

  


### CampaignFeaturePaused

  


### CampaignFeatureUnpaused

  


### UserAdded
> `User Events`
  


### UserModified

  


### UserApproval

  


### UserJoinedCampaign

  


### UserRemoved

  


### CategoryAdded
> `Category Events`
  


### CategoryModified

  


### CategoryDestroyed

  


### FeaturePackageAdded
> `Feature Package Events`
  


### FeaturePackageModified

  


### FeaturePackageDestroyed

  


