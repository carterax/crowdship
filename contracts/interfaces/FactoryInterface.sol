// contracts/FactoryInterface.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract CampaignFactoryInterface {
    address public root;
    address payable public factoryWallet;

    mapping(string => uint256) public campaignTransactionConfig;
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

    function getCampaignTransactionConfig(string memory _prop)
        public
        virtual
        returns (uint256);

    function canManageCampaigns(address _user)
        public
        view
        virtual
        returns (bool);

    function receiveCampaignCommission(uint256 _amount, address campaign)
        external
        virtual;
}
