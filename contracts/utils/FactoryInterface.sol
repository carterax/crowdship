// contracts/FactoryInterface.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract CampaignFactoryInterface {
    address public root;
    address payable public factoryWallet;
    uint256 public defaultCommission;
    uint256 public deadlineStrikesAllowed;
    uint256 public maxDeadlineExtension;
    uint256 public minDeadlineExtension;
    uint256 public minimumContributionAllowed;
    uint256 public maximumContributionAllowed;
    uint256 public minimumRequestAllowed;
    uint256 public maximumRequestAllowed;
    uint256 public minRequestDuration;
    uint256 public maxRequestDuration;
    uint256 public reviewThresholdMark;
    mapping(uint256 => uint256) public categoryCommission;
    mapping(address => bool) public tokensApproved;

    struct CampaignInfo {
        address campaign;
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 category;
        uint256 featureFor;
        bool active;
        bool approved;
        bool exists;
    }
    CampaignInfo[] public deployedCampaigns;
    mapping(address => uint256) public campaignToID;

    struct CampaignCategory {
        uint256 campaignCount;
        uint256 createdAt;
        uint256 updatedAt;
        bool active;
        bool exists;
    }
    CampaignCategory[] public campaignCategories;

    struct User {
        address userAddress;
        uint256 joined;
        uint256 updatedAt;
        bool verified;
        bool exists;
    }
    User[] public users;
    mapping(address => uint256) public userID;

    function canManageCampaigns(address _user)
        public
        view
        virtual
        returns (bool);

    function receiveCampaignCommission(uint256 _amount, address campaign)
        external
        virtual;

    function transferCampaignOwnership(address _newOwner, address _campaign)
        external
        virtual;
}
