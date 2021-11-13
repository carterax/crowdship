// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract ICampaign {
    enum GOALTYPE {
        FIXED,
        FLEXIBLE
    }
    GOALTYPE public goalType;

    enum CAMPAIGN_STATE {
        COLLECTION,
        LIVE,
        REVIEW,
        COMPLETE,
        UNSUCCESSFUL
    }
    CAMPAIGN_STATE public campaignState;

    address public root;
    uint256 public campaignID;
    uint256 public target;
    uint256 public deadline;
    uint256 public campaignBalance;
    uint256 public totalCampaignContribution;
    uint256 public approversCount;
    uint256 public percent;

    address public acceptedToken;
    address public campaignRequestContract;
    address public campaignVoteContract;

    mapping(address => bool) public approvers;

    function getCampaignGoalType() external virtual returns (GOALTYPE);

    function getCampaignState(uint256 state)
        external
        virtual
        returns (CAMPAIGN_STATE);
}
