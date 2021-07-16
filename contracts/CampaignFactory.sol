// contracts/CampaignFactory.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./utils/AccessControl.sol";
import "./Campaign.sol";

contract CampaignFactory is
    Initializable,
    AccessControl,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    /// @dev default role(s)
    bytes32 public constant MANAGE_CATEGORIES = keccak256("MANAGE CATEGORIES");
    bytes32 public constant MANAGE_CAMPAIGNS = keccak256("MANAGE CAMPAIGNS");
    bytes32 public constant MANAGE_USERS = keccak256("MANAGE USERS");

    /// @dev `Campaign Events`
    event CampaignDeployed(
        uint256 indexed campaignId,
        uint256 owner,
        uint256 minimum,
        uint256 category
    );
    event CampaignDestroyed(uint256 indexed campaignId);
    event CampaignApproval(uint256 indexed campaignId, bool approval);
    event CampaignActiveToggle(uint256 indexed campaignId, bool active);
    event CampaignCategoryChange(
        uint256 indexed campaignId,
        uint256 newCategory
    );
    event CampaignFeatured(
        uint256 indexed campaignId,
        uint256 featurePackageId,
        uint256 amount
    );
    event CampaignFeaturePaused(uint256 indexed campaignId);
    event CampaignFeatureUnpaused(uint256 indexed campaignId, uint256 timeLeft);

    /// @dev `User Events`
    event UserAdded(uint256 indexed userId);
    event UserModified(uint256 indexed userId);
    event UserApproval(uint256 indexed userId, bool approval);
    event UserJoinedCampaign(
        uint256 indexed historyId,
        uint256 userId,
        uint256 campaignId
    );
    event UserRemoved(uint256 indexed userId);

    /// @dev `Category Events`
    event CategoryAdded(uint256 indexed categoryId, bool active);
    event CategoryModified(uint256 indexed categoryId, bool active);
    event CategoryDestroyed(uint256 indexed categoryId);

    /// @dev `Feature Package Events`
    event FeaturePackageAdded(
        uint256 indexed packageId,
        uint256 cost,
        uint256 time
    );
    event FeaturePackageModified(
        uint256 indexed packageId,
        uint256 cost,
        uint256 time
    );
    event FeaturePackageDestroyed(uint256 indexed packageId);

    /// @dev Settings
    address public root;
    address payable public factoryWallet;
    address public campaignImplementation;
    uint256 public defaultCommission;
    uint256 public deadlineStrikesAllowed;
    uint256 public maxDeadline;
    uint256 public minDeadline;
    uint256 public factoryRevenue; // total from all activities
    address[] public tokenList;
    mapping(uint256 => uint256) public categoryCommission;
    mapping(address => bool) public tokenInList;
    mapping(address => bool) public tokensApproved;
    mapping(uint256 => uint256) public campaignRevenueFromCommissions; // revenue from cuts
    mapping(uint256 => uint256) public campaignRevenueFromFeatures; // revenue from ads

    /// @dev `Campaigns`
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
    uint256 public campaignCount;
    // uint256[] public featuredCampaigns;
    mapping(address => address) public campaignToOwner;
    mapping(address => uint256) public campaignToID;
    // mapping(uint256 => bool) public campaignHasBeenFeatured;
    mapping(uint256 => bool) public featuredCampaignIsPaused;
    mapping(uint256 => uint256) public pausedFeaturedCampaignTimeLeft;

    /// @dev `Categories`
    struct CampaignCategory {
        uint256 campaignCount;
        uint256 createdAt;
        uint256 updatedAt;
        bool active;
        bool exists;
    }
    CampaignCategory[] public campaignCategories; // array of campaign categories
    uint256 public categoryCount;

    /// @dev `Users`
    struct User {
        address wallet;
        uint256 joined;
        uint256 updatedAt;
        bool verified;
        bool exists;
    }
    User[] public users;
    uint256 public userCount;
    mapping(address => uint256) public userID;

    /// @dev `UserCampaignHistory`
    struct UserCampaignHistory {
        uint256 userId;
        uint256 campaignId;
        uint256 joined;
    }
    UserCampaignHistory[] public userCampaignHistory;

    /// @dev `Featured`
    struct Featured {
        uint256 createdAt;
        uint256 updatedAt;
        uint256 time;
        uint256 cost;
        bool exists;
    }
    Featured[] public featurePackages;
    uint256 public featurePackageCount;

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

    modifier campaignIsEnabled(uint256 _id) {
        require(
            deployedCampaigns[_id].approved && deployedCampaigns[_id].active
        );
        _;
    }

    modifier userOrManager(uint256 _id) {
        require(
            users[_id].wallet == msg.sender || hasRole(MANAGE_USERS, msg.sender)
        );
        _;
    }

    modifier userIsVerified(address _user) {
        require(users[userID[_user]].verified);
        _;
    }

    /// @dev Add `root` to the admin role as a member.
    function __CampaignFactory_init(address payable _wallet)
        public
        initializer
    {
        root = msg.sender;
        factoryWallet = _wallet;
        defaultCommission = 5;
        deadlineStrikesAllowed = 3;
        maxDeadline = 7 days;
        minDeadline = 1 days;

        _setupRole(DEFAULT_ADMIN_ROLE, root);
        _setupRole(MANAGE_CATEGORIES, root);
        _setupRole(MANAGE_CAMPAIGNS, root);
        _setupRole(MANAGE_USERS, root);

        _setRoleAdmin(MANAGE_CATEGORIES, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_CAMPAIGNS, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGE_USERS, DEFAULT_ADMIN_ROLE);

        // add root as user
        signUp();
    }

    function setFactoryWallet(address payable _wallet)
        external
        onlyAdmin
        nonReentrant
    {
        factoryWallet = _wallet;
    }

    function receiveCampaignCommission(uint256 _amount, Campaign campaign)
        external
        onlyCampaignOwner(campaignToID[address(campaign)])
        campaignIsEnabled(campaignToID[address(campaign)])
        campaignExists(campaignToID[address(campaign)])
        nonReentrant
    {
        campaignRevenueFromCommissions[
            campaignToID[address(campaign)]
        ] = campaignRevenueFromCommissions[campaignToID[address(campaign)]].add(
            _amount
        );
        factoryRevenue = factoryRevenue.add(_amount);
    }

    function setCampaignImplementationAddress(Campaign _implementation)
        external
        onlyAdmin
        nonReentrant
    {
        campaignImplementation = address(_implementation);
    }

    function setDefaultCommission(uint256 _commission)
        external
        onlyAdmin
        nonReentrant
    {
        defaultCommission = _commission;
    }

    function setCategoryCommission(uint256 _category, uint256 _commission)
        external
        onlyAdmin
        nonReentrant
    {
        require(campaignCategories[_category].exists);
        categoryCommission[_category] = _commission;
    }

    function addToken(address _token) external onlyAdmin nonReentrant {
        require(!tokenInList[_token]);
        tokenList.push(_token);
        tokenInList[_token] = true;
    }

    function toggleAcceptedToken(address _token, bool _state)
        external
        onlyAdmin
        nonReentrant
    {
        require(tokenInList[_token]);
        tokensApproved[_token] = _state;
    }

    /// @dev Add an account to the manager role. Restricted to admins.
    function addRole(address account, bytes32 role)
        public
        virtual
        onlyAdmin
        nonReentrant
    {
        grantRole(role, account);
    }

    /// @dev Remove an account from the manager role. Restricted to admins.
    function removeRole(address account, bytes32 role)
        public
        virtual
        onlyAdmin
        nonReentrant
    {
        revokeRole(role, account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function canManageCampaigns(address _user) public view returns (bool) {
        return hasRole(MANAGE_CAMPAIGNS, _user);
    }

    function signUp() public whenNotPaused nonReentrant {
        User memory newUser = User(msg.sender, block.timestamp, 0, false, true);
        users.push(newUser);
        userID[msg.sender] = users.length.sub(1);
        userCount = userCount.add(1);

        emit UserAdded(users.length.sub(1));
    }

    function toggleUserApproval(uint256 _userId, bool _approval)
        external
        onlyManager(MANAGE_USERS)
        whenNotPaused
        nonReentrant
    {
        require(users[_userId].exists);
        users[_userId].verified = _approval;
        users[_userId].updatedAt = block.timestamp;

        emit UserApproval(_userId, _approval);
    }

    function destroyUser(uint256 _id)
        external
        onlyManager(MANAGE_USERS)
        whenNotPaused
        nonReentrant
    {
        User storage user = users[_id];
        require(user.exists);
        delete users[_id];

        emit UserRemoved(_id);
    }

    function addCampaignToUserHistory(address _campaign)
        external
        campaignExists(campaignToID[_campaign])
        whenNotPaused
        nonReentrant
    {
        CampaignInfo storage campaign = deployedCampaigns[
            campaignToID[_campaign]
        ];
        require(Campaign(campaign.campaign).approvers(msg.sender));
        userCampaignHistory.push(
            UserCampaignHistory(
                userID[msg.sender],
                campaignToID[_campaign],
                block.timestamp
            )
        );

        emit UserJoinedCampaign(
            userCampaignHistory.length.sub(1),
            userID[msg.sender],
            campaignToID[_campaign]
        );
    }

    function createCampaign(uint256 _minimum, uint256 _category)
        external
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        // check `_category` exists and active
        require(
            campaignCategories[_category].exists &&
                campaignCategories[_category].active
        );

        address campaign = ClonesUpgradeable.clone(campaignImplementation);

        CampaignInfo memory campaignInfo = CampaignInfo({
            campaign: address(campaign),
            category: _category,
            owner: msg.sender,
            createdAt: block.timestamp,
            updatedAt: 0,
            featureFor: 0,
            active: false,
            approved: false,
            exists: true
        });
        deployedCampaigns.push(campaignInfo);
        campaignToOwner[address(campaign)] = msg.sender; // keep track of campaign owner

        uint256 campaignId = deployedCampaigns.length.sub(1);
        campaignToID[address(campaign)] = campaignId;

        campaignCategories[_category].campaignCount = campaignCategories[
            _category
        ]
        .campaignCount
        .add(1);
        campaignCount = campaignCount.add(1);

        Campaign(campaign).__Campaign_init(address(this), msg.sender);

        // emit event
        emit CampaignDeployed(
            campaignId,
            userID[msg.sender],
            _minimum,
            _category
        );
    }

    function toggleCampaignApproval(uint256 _id, bool _approval)
        external
        onlyManager(MANAGE_CAMPAIGNS)
        campaignExists(_id)
        whenNotPaused
        nonReentrant
    {
        deployedCampaigns[_id].approved = _approval;
        deployedCampaigns[_id].updatedAt = block.timestamp;

        emit CampaignApproval(_id, _approval);
    }

    function toggleCampaignActive(uint256 _id, bool _active)
        external
        campaignOwnerOrManager(_id)
        campaignExists(_id)
        whenNotPaused
        nonReentrant
    {
        deployedCampaigns[_id].active = _active;
        deployedCampaigns[_id].updatedAt = block.timestamp;

        emit CampaignActiveToggle(_id, _active);
    }

    function modifyCampaignCategory(uint256 _id, uint256 _newCategory)
        external
        campaignOwnerOrManager(_id)
        campaignExists(_id)
        whenNotPaused
        nonReentrant
    {
        uint256 _oldCategory = deployedCampaigns[_id].category;

        if (_oldCategory != _newCategory) {
            require(campaignCategories[_newCategory].exists);

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

            deployedCampaigns[_id].updatedAt = block.timestamp;

            emit CampaignCategoryChange(_id, _newCategory);
        }
    }

    function featureCampaign(
        uint256 _campaignId,
        uint256 _featurePackageId,
        address _token
    )
        external
        payable
        onlyCampaignOwner(_campaignId)
        campaignExists(_campaignId)
        campaignIsEnabled(_campaignId)
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        require(tokensApproved[_token]);
        require(featurePackages[_featurePackageId].exists);
        require(featurePackages[_featurePackageId].cost >= msg.value);

        // update campaign revenue to factory
        factoryRevenue = factoryRevenue.add(msg.value);

        // update campaign revenue from ads
        campaignRevenueFromFeatures[_campaignId] = campaignRevenueFromFeatures[
            _campaignId
        ]
        .add(msg.value);

        // update featuredFor for time specified in the selected feature package
        deployedCampaigns[_campaignId].featureFor = deployedCampaigns[
            _campaignId
        ]
        .featureFor
        .add(featurePackages[_featurePackageId].time)
        .add(block.timestamp);

        deployedCampaigns[_campaignId].updatedAt = block.timestamp;

        // transfer funds to factory wallet
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(_token),
            msg.sender,
            factoryWallet,
            msg.value
        );

        emit CampaignFeatured(_campaignId, _featurePackageId, msg.value);
    }

    function pauseCampaignFeatured(uint256 _campaignId)
        external
        onlyCampaignOwner(_campaignId)
        campaignExists(_campaignId)
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        require(deployedCampaigns[_campaignId].featureFor >= block.timestamp); // check time in campaign feature hasn't expired
        require(!featuredCampaignIsPaused[_campaignId]); // make sure campaign feature isn't paused

        // time in campaign currently - current time
        pausedFeaturedCampaignTimeLeft[_campaignId] = deployedCampaigns[
            _campaignId
        ]
        .featureFor
        .sub(block.timestamp);

        featuredCampaignIsPaused[_campaignId] = true;

        emit CampaignFeaturePaused(_campaignId);
    }

    function unpauseCampaignFeatured(uint256 _campaignId)
        external
        onlyCampaignOwner(_campaignId)
        campaignExists(_campaignId)
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        //require(deployedCampaigns[_campaignId].featureFor > block.timestamp, "feature is");
        require(featuredCampaignIsPaused[_campaignId]); // make sure campaign feature is paused

        featuredCampaignIsPaused[_campaignId] = false;

        deployedCampaigns[_campaignId].featureFor = deployedCampaigns[
            _campaignId
        ]
        .featureFor
        .add(pausedFeaturedCampaignTimeLeft[_campaignId]);

        // we don't owe you no more
        pausedFeaturedCampaignTimeLeft[_campaignId] = 0;

        emit CampaignFeatureUnpaused(
            _campaignId,
            pausedFeaturedCampaignTimeLeft[_campaignId]
        );
    }

    function destroyCampaign(uint256 _id)
        external
        onlyManager(MANAGE_CAMPAIGNS)
        campaignExists(_id)
        whenNotPaused
        nonReentrant
    {
        // delete the campaign from array
        delete deployedCampaigns[_id];

        // emit event
        emit CampaignDestroyed(_id);
    }

    function createCategory(bool _active)
        external
        onlyManager(MANAGE_CATEGORIES)
        whenNotPaused
        nonReentrant
    {
        // create category with `campaignCount` default to 0
        CampaignCategory memory newCategory = CampaignCategory({
            campaignCount: 0,
            createdAt: block.timestamp,
            updatedAt: 0,
            active: _active,
            exists: true
        });
        campaignCategories.push(newCategory);

        categoryCount = categoryCount.add(1);

        emit CategoryAdded(campaignCategories.length.sub(1), _active);
    }

    function modifyCategory(uint256 _id, bool _active)
        external
        onlyManager(MANAGE_CATEGORIES)
        whenNotPaused
        nonReentrant
    {
        require(campaignCategories[_id].exists);

        campaignCategories[_id].active = _active;
        campaignCategories[_id].updatedAt = block.timestamp;

        emit CategoryModified(_id, _active);
    }

    function destroyCategory(uint256 _id)
        external
        onlyManager(MANAGE_CATEGORIES)
        whenNotPaused
        nonReentrant
    {
        // check if category exists
        require(campaignCategories[_id].exists);

        // delete the category from `campaignCategories`
        delete campaignCategories[_id];

        emit CategoryDestroyed(_id);
    }

    function createFeaturePackage(uint256 _cost, uint256 _time)
        external
        onlyAdmin
        whenNotPaused
        nonReentrant
    {
        featurePackages.push(Featured(block.timestamp, 0, _time, _cost, true));
        featurePackageCount = featurePackageCount.add(1);

        emit FeaturePackageAdded(featurePackages.length.sub(1), _cost, _time);
    }

    function modifyFeaturedPackage(
        uint256 _packageId,
        uint256 _cost,
        uint256 _time
    ) external onlyAdmin whenNotPaused nonReentrant {
        require(featurePackages[_packageId].exists);
        featurePackages[_packageId].cost = _cost;
        featurePackages[_packageId].time = _time;
        featurePackages[_packageId].updatedAt = block.timestamp;

        emit FeaturePackageModified(_packageId, _cost, _time);
    }

    function destroyFeaturedPackage(uint256 _packageId)
        external
        onlyAdmin
        whenNotPaused
        nonReentrant
    {
        require(featurePackages[_packageId].exists);

        delete featurePackages[_packageId];

        emit FeaturePackageDestroyed(_packageId);
    }

    function unpauseCampaign() external whenPaused onlyAdmin nonReentrant {
        _unpause();
    }

    function pauseCampaign() external whenNotPaused onlyAdmin nonReentrant {
        _pause();
    }
}
