// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../campaign/Campaign.sol";

abstract contract ICampaignFactory {
    address public root;
    address public campaignFactoryAddress;
    address payable public factoryWallet;

    mapping(string => uint256) public campaignTransactionConfig;
    mapping(uint256 => uint256) public categoryCommission;

    struct CampaignInfo {
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 category;
        string hahedCampaignInfo;
        bool active;
        bool privateCampaign;
    }
    mapping(Campaign => CampaignInfo) public campaigns;

    struct CampaignCategory {
        uint256 campaignCount;
        uint256 createdAt;
        uint256 updatedAt;
        string hashedCategory;
        bool active;
        bool exists;
    }
    CampaignCategory[] public campaignCategories;

    struct User {
        uint256 joined;
        uint256 updatedAt;
        string hashedUser;
        bool verified;
    }
    mapping(address => User) public users;

    struct Token {
        address token;
        string hashedToken;
        bool approved;
    }
    mapping(address => Token) public tokens;

    mapping(address => mapping(address => bool)) public isUserTrustee;
    mapping(address => bool) public accountInTransit;

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
