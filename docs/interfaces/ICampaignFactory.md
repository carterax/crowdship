# ICampaignFactory





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| root | address |
| campaignFactoryAddress | address |
| factoryWallet | address payable |
| campaignTransactionConfig | mapping(string => uint256) |
| categoryCommission | mapping(uint256 => uint256) |
| campaigns | mapping(contract Campaign => struct ICampaignFactory.CampaignInfo) |
| campaignCategories | struct ICampaignFactory.CampaignCategory[] |
| users | mapping(address => struct ICampaignFactory.User) |
| tokens | mapping(address => struct ICampaignFactory.Token) |
| isUserTrustee | mapping(address => mapping(address => bool)) |
| accountInTransit | mapping(address => bool) |



## Functions

### getCampaignTransactionConfig


#### Declaration
```solidity
  function getCampaignTransactionConfig(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers


---  
### canManageCampaigns


#### Declaration
```solidity
  function canManageCampaigns(
  ) public returns (bool)
```

#### Modifiers:
No modifiers


---  
### receiveCampaignCommission


#### Declaration
```solidity
  function receiveCampaignCommission(
  ) external
```

#### Modifiers:
No modifiers


---  


