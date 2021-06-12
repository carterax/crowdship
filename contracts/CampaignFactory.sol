// contracts/CampaignFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./utils/AccessControl.sol";
import "./Campaign.sol";

contract CampaignFactory is Initializable, AccessControl {
    using SafeMathUpgradeable for uint256;

    /// @dev default role(s)
    bytes32 public constant MANAGE_ANALYTICS = keccak256("MANAGE ANALYTICS");
    bytes32 public constant MANAGE_CATEGORIES = keccak256("MANAGE CATEGORIES");
    bytes32 public constant MANAGE_CAMPAIGNS = keccak256("MANAGE CAMPAIGNS");
    bytes32 public constant MANAGE_SETTINGS = keccak256("MANAGE SETTINGS");

    event CampaignDeployed(address campaign);
    event CampaignDestroyed(uint256 indexed id);

    address public root;

    struct CampaignInfo {
        address campaign;
        bool featured;
        bool active;
        bool approved;
        bool exists;
    }
    CampaignInfo[] public deployedCampaigns;
    mapping(address => address) public campaignToOwner;
    mapping(address => uint256) public campaignToID;

    /// @dev `Categories`
    struct CampaignCategory {
        string title;
        uint256 campaignCount;
        bool active;
        bool exists;
    }
    CampaignCategory[] public campaignCategories; // array of campaign categories
    mapping(string => bool) public categoryIsTaken; // maintain unique category names

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

    /// @dev Add `root` to the admin role as a member.
    function __CampaignFactory_init(address _root) public initializer {
        root = _root;

        _setupRole(DEFAULT_ADMIN_ROLE, _root);
        _setupRole(MANAGE_ANALYTICS, _root);
        _setupRole(MANAGE_CATEGORIES, _root);
        _setupRole(MANAGE_CAMPAIGNS, _root);
        _setupRole(MANAGE_SETTINGS, _root);

        _setRoleAdmin(MANAGE_ANALYTICS, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_CATEGORIES, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_CAMPAIGNS, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_SETTINGS, DEFAULT_ADMIN_ROLE);
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

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createCampaign(uint256 _minimum, uint256 _category) external {
        // TODO: check `_category` exists
        require(
            campaignCategories[_category].exists &&
                campaignCategories[_category].active
        );

        Campaign newCampaign = new Campaign();
        newCampaign.__Campaign_init(
            address(this),
            msg.sender,
            _category,
            _minimum
        );
        CampaignInfo memory campaignInfo =
            CampaignInfo({
                campaign: address(newCampaign),
                featured: false,
                active: false,
                approved: false,
                exists: true
            });
        deployedCampaigns.push(campaignInfo);
        campaignToOwner[address(newCampaign)] = msg.sender; // keep track of campaign owner
        campaignToID[address(newCampaign)] = deployedCampaigns.length.sub(1);

        // emit event
        emit CampaignDeployed(address(newCampaign));
    }

    function approveCampaign(uint256 _id)
        external
        onlyManager(MANAGE_CAMPAIGNS)
        campaignExists(_id)
    {
        deployedCampaigns[_id].approved = true;
    }

    function toggleCampaignState(uint256 _id, bool _state)
        external
        campaignOwnerOrManager(_id)
        campaignExists(_id)
    {
        deployedCampaigns[_id].active = _state;
    }

    // TODO:
    function toggleCampaignFeatured(uint256 _id, bool _state)
        external
        onlyCampaignOwner(_id)
        campaignExists(_id)
    {
        // check amount sent matches specified time in which campaign can be featured
        deployedCampaigns[_id].featured = _state;
    }

    function getDeployedCampaigns()
        public
        view
        returns (CampaignInfo[] memory)
    {
        return deployedCampaigns;
    }

    // TODO: user concensus feature
    function destroyCampaign(uint256 _id) public campaignOwnerOrManager(_id) {
        // delete the campaign from array
        delete deployedCampaigns[_id];

        // emit event
        emit CampaignDestroyed(_id);
    }

    function createCategory(string memory _title, bool _active)
        public
        onlyManager(MANAGE_CATEGORIES)
    {
        // check if category exists
        require(!categoryIsTaken[_title]);

        // create category with `campaignCount` default to 0
        CampaignCategory memory newCategory =
            CampaignCategory({
                title: _title,
                campaignCount: 0,
                active: _active,
                exists: true
            });
        campaignCategories.push(newCategory);

        // set category name as taken
        categoryIsTaken[_title] = true;
    }

    function getCategories() public view returns (CampaignCategory[] memory) {
        return campaignCategories;
    }

    function destroyCategory(uint256 _id)
        public
        onlyManager(MANAGE_CATEGORIES)
    {
        // check if category exists
        require(campaignCategories[_id].exists);

        // delete the category from `campaignCategories`
        delete campaignCategories[_id];

        // set the category name as being available
        categoryIsTaken[campaignCategories[_id].title] = false;
    }

    function getDeployedCampaignsCount() public view returns (uint256) {
        return deployedCampaigns.length;
    }

    function getCategoriesCount() public view returns (uint256) {
        return campaignCategories.length;
    }
}
