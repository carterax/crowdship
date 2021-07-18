# CampaignFactoryInterface





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| root | address |
| factoryWallet | address payable |
| defaultCommission | uint256 |
| deadlineStrikesAllowed | uint256 |
| maxDeadline | uint256 |
| minDeadline | uint256 |
| minimumContributionAllowed | uint256 |
| maximumContributionAllowed | uint256 |
| categoryCommission | mapping(uint256 => uint256) |
| tokensApproved | mapping(address => bool) |
| deployedCampaigns | struct CampaignFactoryInterface.CampaignInfo[] |
| campaignToID | mapping(address => uint256) |
| campaignCategories | struct CampaignFactoryInterface.CampaignCategory[] |
| users | struct CampaignFactoryInterface.User[] |
| userID | mapping(address => uint256) |



## Functions

### canManageCampaigns


#### Declaration
```solidity
  function canManageCampaigns(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### receiveCampaignCommission


#### Declaration
```solidity
  function receiveCampaignCommission(
  ) external
```

#### Modifiers:
No modifiers





