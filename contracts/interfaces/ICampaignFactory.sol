// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../campaign/Campaign.sol";

abstract contract ICampaignFactory {
    address public root;
    address public campaignFactoryAddress;
    address payable public factoryWallet;

    mapping(string => uint256) public campaignTransactionConfig;
    mapping(uint256 => uint256) public categoryCommission;
    mapping(address => bool) public tokensApproved;

    struct CampaignInfo {
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 category;
        bool active;
        bool approved;
    }
    mapping(Campaign => CampaignInfo) public campaigns;

    struct CampaignCategory {
        uint256 campaignCount;
        uint256 createdAt;
        uint256 updatedAt;
        bool active;
        bool exists;
    }
    CampaignCategory[] public campaignCategories;

    struct User {
        uint256 joined;
        uint256 updatedAt;
        bool verified;
    }
    mapping(address => User) public users;

    mapping(address => mapping(address => bool)) public isUserTrustee;

    function getCampaignTransactionConfig(string memory _prop)
        public
        virtual
        returns (uint256);

    function canManageCampaigns(address _user)
        public
        view
        virtual
        returns (bool);

    function receiveCampaignCommission(Campaign _campaign, uint256 _amount)
        external
        virtual;
}
