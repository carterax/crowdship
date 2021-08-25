# CampaignFactoryLib





## Contents
<!-- START doctoc -->
<!-- END doctoc -->




## Functions

### canManageCampaigns


#### Declaration
```solidity
  function canManageCampaigns(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers


---  
### getCampaignFactoryConfig
>        Returns information on a campaign from the factory


#### Declaration
```solidity
  function getCampaignFactoryConfig(
    contract CampaignFactoryInterface _factory,
    string _prop
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_factory` | contract CampaignFactoryInterface |     Campaign factory interface
|`_prop` | string |        Transaction setting key
---  
### campaignInfo
>        Returns information on a campaign from the factory


#### Declaration
```solidity
  function campaignInfo(
    contract CampaignFactoryInterface _factory,
    uint256 _campaignId
  ) internal returns (address, uint256, bool, bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_factory` | contract CampaignFactoryInterface |     Campaign factory interface
|`_campaignId` | uint256 |  ID of the campaign
---  
### userInfo
>        Returns information about a user from the factory


#### Declaration
```solidity
  function userInfo(
    contract CampaignFactoryInterface _factory,
    address _userAddress
  ) internal returns (address, bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_factory` | contract CampaignFactoryInterface |      Campaign factory interface
|`_userAddress` | address |  Address of the user
---  
### factoryPercentFee
>        Returns factory percentage cut on all requests per category


#### Declaration
```solidity
  function factoryPercentFee(
    contract CampaignFactoryInterface _factory,
    uint256 _campaignId
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_factory` | contract CampaignFactoryInterface |     Campaign factory interface
|`_campaignId` | uint256 |  ID of the campaign
---  


