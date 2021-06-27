// contracts/CampaignFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./utils/AccessControl.sol";
import "./Campaign.sol";

contract CampaignFactory is
    Initializable,
    AccessControl,
    PullPaymentUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    /// @dev default role(s)
    bytes32 public constant MANAGE_ANALYTICS = keccak256("MANAGE ANALYTICS");
    bytes32 public constant MANAGE_CATEGORIES = keccak256("MANAGE CATEGORIES");
    bytes32 public constant MANAGE_CAMPAIGNS = keccak256("MANAGE CAMPAIGNS");
    bytes32 public constant MANAGE_SETTINGS = keccak256("MANAGE SETTINGS");
    bytes32 public constant MANAGE_USERS = keccak256("MANAGE USERS");

    event CampaignDeployed(address campaign);
    event CampaignDestroyed(uint256 indexed id);

    event UserAdded(uint256 indexed id);
    event UserRemoved(uint256 indexed id);

    /// @dev Settings
    address public root;
    address public campaignImplementation;
    uint256 public factoryCutPercentage;
    uint256 public deadlineStrikesAllowed;
    uint256 public maxDeadline;
    uint256 public minDeadline;

    /// @dev `Campaigns`
    struct CampaignInfo {
        address campaign;
        address owner;
        string title;
        string pitch;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 category;
        uint256 featureFor;
        bool featured;
        bool active;
        bool approved;
        bool exists;
    }
    CampaignInfo[] public deployedCampaigns;
    mapping(address => address) public campaignToOwner;
    mapping(address => uint256[]) public campaignsByUser;
    mapping(address => uint256) public campaignToID;

    /// @dev `Categories`
    struct CampaignCategory {
        string title;
        uint256 campaignCount;
        uint256 createdAt;
        uint256 updatedAt;
        bool active;
        bool exists;
    }
    CampaignCategory[] public campaignCategories; // array of campaign categories
    mapping(string => bool) public categoryIsTaken; // maintain unique category names
    mapping(uint256 => uint256[]) public campaignToCategories;

    /// @dev `Users`
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
    mapping(string => bool) public usernameIsTaken;
    mapping(string => bool) public emailIsTaken;

    modifier campaignOwnerOrManager(uint256 _id) {
        require(
            campaignToOwner[deployedCampaigns[_id].campaign] == msg.sender ||
                hasRole(MANAGE_CAMPAIGNS, msg.sender)
        );
        _;
    }

    modifier onlyCampaignOwner(uint256 _id) {
        require(campaignToOwner[deployedCampaigns[_id].campaign] == msg.sender);
        _;
    }

    modifier campaignExists(uint256 _id) {
        require(deployedCampaigns[_id].exists);
        _;
    }

    modifier userOrManager(uint256 _id) {
        require(
            users[_id].wallet == msg.sender || hasRole(MANAGE_USERS, msg.sender)
        );
        _;
    }

    /// @dev Add `root` to the admin role as a member.
    function __CampaignFactory_init(
        address _root,
        string memory _email,
        string memory _username
    ) public initializer {
        root = _root;

        factoryCutPercentage = 5;
        deadlineStrikesAllowed = 3;
        maxDeadline = 7 days;
        minDeadline = 1 days;

        _setupRole(DEFAULT_ADMIN_ROLE, _root);
        _setupRole(MANAGE_ANALYTICS, _root);
        _setupRole(MANAGE_CATEGORIES, _root);
        _setupRole(MANAGE_CAMPAIGNS, _root);
        _setupRole(MANAGE_SETTINGS, _root);
        _setupRole(MANAGE_USERS, _root);

        _setRoleAdmin(MANAGE_ANALYTICS, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_CATEGORIES, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_CAMPAIGNS, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_SETTINGS, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_USERS, DEFAULT_ADMIN_ROLE);

        // add root as user
        signUp(_email, _username);
    }

    function setCampaignImplementationAddress(address _implementation)
        external
        onlyAdmin
    {
        campaignImplementation = _implementation;
    }

    /// @dev Add an account to the manager role. Restricted to admins.
    function addRole(address account, bytes32 role) public virtual onlyAdmin {
        grantRole(role, account);
    }

    /// @dev Remove an account from the manager role. Restricted to admins.
    function removeRole(address account, bytes32 role)
        public
        virtual
        onlyAdmin
    {
        revokeRole(role, account);
    }

    function canManageCampaigns(address _user) external view returns (bool) {
        return hasRole(MANAGE_CAMPAIGNS, _user);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setFactoryCut(uint256 _cut) external onlyAdmin {
        factoryCutPercentage = _cut;
    }

    function signUp(string memory _email, string memory _username)
        public
        whenNotPaused
    {
        require(!usernameIsTaken[_username] && !emailIsTaken[_email]);

        User memory newUser = User(
            msg.sender,
            _email,
            _username,
            block.timestamp,
            0,
            false,
            true
        );
        users.push(newUser);
        userID[msg.sender] = users.length.sub(1);
        usernameIsTaken[_username] = true;
        emailIsTaken[_email] = true;

        emit UserAdded(users.length.sub(1));
    }

    function toggleUserApproval(uint256 _userId, bool _approval)
        external
        onlyManager(MANAGE_USERS)
        whenNotPaused
    {
        users[_userId].verified = _approval;
    }

    function modifyUser(
        uint256 _id,
        string memory _email,
        string memory _username
    ) external userOrManager(_id) whenNotPaused {
        require(users[_id].exists);

        if (!emailIsTaken[_email]) {
            string storage oldMail = users[_id].email;
            emailIsTaken[oldMail] = false;

            users[_id].email = _email;
            users[_id].verified = false;
            emailIsTaken[_email] = true;
        }

        if (!usernameIsTaken[_username]) {
            string storage oldUsername = users[_id].username;
            usernameIsTaken[oldUsername] = false;

            users[_id].username = _username;
            usernameIsTaken[_username] = true;
        }

        users[_id].updatedAt = block.timestamp;
    }

    function destroyUser(uint256 _id)
        external
        onlyManager(MANAGE_USERS)
        whenNotPaused
    {
        User storage user = users[_id];
        require(user.exists);
        usernameIsTaken[user.username] = false;
        emailIsTaken[user.email] = false;
        delete users[_id];

        emit UserRemoved(_id);
    }

    function createCampaign(
        uint256 _minimum,
        uint256 _category,
        string memory _title,
        string memory _pitch
    ) external whenNotPaused {
        // check `_category` exists
        // check `user` verified
        require(
            campaignCategories[_category].exists &&
                campaignCategories[_category].active &&
                users[userID[msg.sender]].verified
        );
        address campaign = ClonesUpgradeable.clone(campaignImplementation);
        Campaign(campaign).__Campaign_init(address(this), msg.sender, _minimum);

        CampaignInfo memory campaignInfo = CampaignInfo({
            campaign: address(campaign),
            title: _title,
            pitch: _pitch,
            category: _category,
            owner: msg.sender,
            createdAt: block.timestamp,
            updatedAt: 0,
            featured: false,
            featureFor: 0,
            active: false,
            approved: false,
            exists: true
        });
        deployedCampaigns.push(campaignInfo);
        campaignToOwner[address(campaign)] = msg.sender; // keep track of campaign owner

        uint256 campaignId = deployedCampaigns.length.sub(1);
        campaignToID[address(campaign)] = campaignId;

        campaignsByUser[msg.sender].push(campaignId);
        campaignToCategories[_category].push(_category);

        campaignCategories[_category].campaignCount = campaignCategories[
            _category
        ]
        .campaignCount
        .add(1);

        // emit event
        emit CampaignDeployed(address(campaign));
    }

    function toggleCampaignApproval(uint256 _id, bool _approval)
        external
        onlyManager(MANAGE_CAMPAIGNS)
        whenNotPaused
    {
        deployedCampaigns[_id].approved = _approval;
        deployedCampaigns[_id].updatedAt = block.timestamp;
    }

    function toggleCampaignActive(uint256 _id, bool _active)
        external
        campaignOwnerOrManager(_id)
        campaignExists(_id)
        whenNotPaused
    {
        deployedCampaigns[_id].active = _active;
        deployedCampaigns[_id].updatedAt = block.timestamp;
    }

    function modifyCampaignSummary(
        uint256 _id,
        uint256 _newCategory,
        string memory _newTitle,
        string memory _newPitch
    ) external campaignOwnerOrManager(_id) campaignExists(_id) whenNotPaused {
        uint256 _oldCategory = deployedCampaigns[_id].category;

        if (_oldCategory != _newCategory) {
            deployedCampaigns[_id].category = _newCategory;
            campaignCategories[_oldCategory].campaignCount = campaignCategories[
                _oldCategory
            ]
            .campaignCount
            .sub(1);
            campaignCategories[_newCategory].campaignCount = campaignCategories[
                _newCategory
            ]
            .campaignCount
            .add(1);
        }

        deployedCampaigns[_id].title = _newTitle;
        deployedCampaigns[_id].pitch = _newPitch;
        deployedCampaigns[_id].updatedAt = block.timestamp;
    }

    // TODO:
    function toggleCampaignFeatured(uint256 _id, bool _state)
        external
        onlyCampaignOwner(_id)
        campaignExists(_id)
        whenNotPaused
    {
        // check amount sent matches specified time in which campaign can be featured
        deployedCampaigns[_id].featured = _state;
        deployedCampaigns[_id].featureFor = 0; // switch statement needed here
        deployedCampaigns[_id].updatedAt = block.timestamp;
    }

    function destroyCampaign(uint256 _id)
        public
        campaignOwnerOrManager(_id)
        whenNotPaused
    {
        // delete the campaign from array
        delete deployedCampaigns[_id];

        // emit event
        emit CampaignDestroyed(_id);
    }

    function createCategory(string memory _title, bool _active)
        public
        onlyManager(MANAGE_CATEGORIES)
        whenNotPaused
    {
        // check if category exists
        require(!categoryIsTaken[_title]);

        // create category with `campaignCount` default to 0
        CampaignCategory memory newCategory = CampaignCategory({
            title: _title,
            campaignCount: 0,
            createdAt: block.timestamp,
            updatedAt: 0,
            active: _active,
            exists: true
        });
        campaignCategories.push(newCategory);

        // set category name as taken
        categoryIsTaken[_title] = true;
    }

    function modifyCategory(
        uint256 _id,
        string memory _title,
        bool _active
    ) external onlyManager(MANAGE_CATEGORIES) whenNotPaused {
        require(campaignCategories[_id].exists);

        if (!categoryIsTaken[_title]) {
            categoryIsTaken[campaignCategories[_id].title] = false;
            campaignCategories[_id].title = _title;
            categoryIsTaken[_title] = true;
        }
        campaignCategories[_id].active = _active;
        campaignCategories[_id].updatedAt = block.timestamp;
    }

    function destroyCategory(uint256 _id)
        public
        onlyManager(MANAGE_CATEGORIES)
        whenNotPaused
    {
        // check if category exists
        require(campaignCategories[_id].exists);

        // delete the category from `campaignCategories`
        delete campaignCategories[_id];

        // set the category name as being available
        categoryIsTaken[campaignCategories[_id].title] = false;
    }

    function unPauseCampaign() external whenPaused onlyAdmin {
        _unpause();
    }

    function pauseCampaign() external whenNotPaused onlyAdmin {
        _pause();
    }
}
