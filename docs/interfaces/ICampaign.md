# ICampaign





## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| goalType | enum ICampaign.GOALTYPE |
| campaignState | enum ICampaign.CAMPAIGN_STATE |
| root | address |
| campaignID | uint256 |
| target | uint256 |
| deadline | uint256 |
| campaignBalance | uint256 |
| totalCampaignContribution | uint256 |
| approversCount | uint256 |
| percent | uint256 |
| acceptedToken | address |
| campaignRequestContract | address |
| campaignVoteContract | address |
| approvers | mapping(address => bool) |



## Functions

### isCampaignAdmin


#### Declaration
```solidity
  function isCampaignAdmin(
  ) external returns (bool)
```

#### Modifiers:
No modifiers


---  
### isCampaignManager


#### Declaration
```solidity
  function isCampaignManager(
  ) external returns (bool)
```

#### Modifiers:
No modifiers


---  
### getCampaignGoalType


#### Declaration
```solidity
  function getCampaignGoalType(
  ) external returns (enum ICampaign.GOALTYPE)
```

#### Modifiers:
No modifiers


---  
### getCampaignState


#### Declaration
```solidity
  function getCampaignState(
  ) external returns (enum ICampaign.CAMPAIGN_STATE)
```

#### Modifiers:
No modifiers


---  


