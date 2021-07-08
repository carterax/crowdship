// contracts/FactoryInterface.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract CampaignFactoryInterface {
    address public root;
    uint256 public defaultCommission;
    uint256 public deadlineStrikesAllowed;
    uint256 public maxDeadline;
    uint256 public minDeadline;
    mapping(uint256 => uint256) public categoryCommission;

    struct CampaignInfo {
        address campaign;
        uint256 category;
        bool featured;
        bool active;
        bool approved;
    }
    CampaignInfo[] public deployedCampaigns;
    mapping(address => uint256) public campaignToID;

    struct CampaignCategory {
        string title;
        uint256 campaignCount;
        uint256 createdAt;
        uint256 updatedAt;
        bool active;
        bool exists;
    }
    CampaignCategory[] public campaignCategories;

    struct User {
        address wallet;
        string email;
        string username;
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

    function addCampaignToUserHistory(address _campaign) external virtual;
}
