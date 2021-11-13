// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Campaign.sol";
import "./CampaignReward.sol";
import "./CampaignRequest.sol";
import "./CampaignVote.sol";

import "../utils/AccessControl.sol";
import "../libraries/math/DecimalMath.sol";

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

    /// @dev `Factory Config Events`
    event FactoryConfigUpdated(
        address factoryWallet,
        address campaignImplementation,
        address campaignRewardsImplementation,
        address campaignRequestsImplementation,
        address campaignVotesImplementation
    );
    event CategoryCommissionUpdated(
        uint256 indexed categoryId,
        uint256 commission
    );
    event CampaignDefaultCommissionUpdated(uint256 commission);
    event CampaignTransactionConfigUpdated(string prop, uint256 value);

    /// @dev `Campaign Events`
    event CampaignDeployed(
        address factory,
        address campaign,
        address campaignRewards,
        address campaignRequests,
        address campaignVotes,
        uint256 category,
        bool approved
    );
    event CampaignApproval(address indexed campaign, bool approval);
    event CampaignActiveToggle(address indexed campaign, bool active);
    event CampaignCategoryChange(address indexed campaign, uint256 newCategory);

    /// @dev `Token Events`
    event TokenAdded(address indexed token);
    event TokenApproval(address indexed token, bool state);

    /// @dev `User Events`
    event UserAdded(uint256 indexed userId);
    event UserApproval(
        uint256 indexed userId,
        address indexed user,
        bool approval
    );

    /// @dev `Trustee Events`
    event TrusteeAdded(uint256 indexed trusteeId, address trusteeAddress);
    event TrusteeRemoved(uint256 indexed trusteeId, address trusteeAddress);

    /// @dev `Category Events`
    event CategoryAdded(uint256 indexed categoryId, bool active);
    event CategoryModified(uint256 indexed categoryId, bool active);

    /// @dev Settings
    address public root;
    address public campaignFactoryAddress;
    address payable public factoryWallet;
    address public campaignImplementation;
    address public campaignRewardsImplementation;
    address public campaignVotesImplementation;
    address public campaignRequestsImplementation;
    string[] public campaignTransactionConfigList;
    mapping(string => bool) public approvedCampaignTransactionConfig;
    mapping(string => uint256) public campaignTransactionConfig;
    mapping(uint256 => uint256) public categoryCommission;
    mapping(address => bool) public tokenInList;
    mapping(address => bool) public tokensApproved;

    /// @dev Revenue
    uint256 public factoryRevenue; // total from all campaigns
    mapping(uint256 => uint256) public campaignRevenueFromCommissions; // revenue from cuts

    /// @dev `Campaigns`
    struct CampaignInfo {
        address campaign;
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 category;
        bool approved;
    }
    CampaignInfo[] public deployedCampaigns;
    uint256 public campaignCount;
    mapping(address => address) public campaignToOwner;
    mapping(address => uint256) public campaignToID;

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
        address userAddress;
        uint256 joined;
        uint256 updatedAt;
        bool verified;
        bool exists;
    }
    User[] public users;
    uint256 public userCount;
    mapping(address => uint256) public userID;

    struct Trust {
        address trustee;
        address trustor;
        uint256 createdAt;
        bool isTrusted;
    }
    Trust[] public trustees;
    mapping(address => uint256) public userTrusteeCount;

    // { trustor -> trustee -> isTrusted }
    mapping(address => mapping(address => bool)) public isUserTrustee;

    /// @dev Ensures caller is campaign owner alone
    modifier campaignOwner(uint256 _campaignId) {
        require(
            deployedCampaigns[_campaignId].owner == msg.sender,
            "only campaign owner"
        );
        _;
    }

    /// @dev Ensures caller is a registered campaign contract from factory
    modifier onlyRegisteredCampaigns(uint256 _campaignId) {
        require(
            deployedCampaigns[_campaignId].campaign == msg.sender,
            "only campaign owner"
        );
        _;
    }

    /**
     * @dev        Contructor
     * @param      _wallet     Address where all revenue gets deposited
     */
    function __CampaignFactory_init(address payable _wallet, address _root)
        public
        initializer
    {
        require(address(_wallet) != address(0));
        root = _root;
        factoryWallet = _wallet;
        campaignFactoryAddress = address(this);

        string[15] memory transactionConfigs = [
            "defaultCommission",
            "deadlineStrikesAllowed",
            "minimumContributionAllowed",
            "maximumContributionAllowed",
            "minimumRequestAmountAllowed",
            "maximumRequestAmountAllowed",
            "minimumCampaignTarget",
            "maximumCampaignTarget",
            "maxDeadlineExtension",
            "minDeadlineExtension",
            "minRequestDuration",
            "maxRequestDuration",
            "reviewThresholdMark",
            "requestFinalizationThreshold",
            "reportThresholdMark"
        ];

        uint24[15] memory defaultTransactionConfigValues = [
            2, // defaultCommission
            3, // deadlineStrikesAllowed
            1, // minimumContributionAllowed
            10000, // maximumContributionAllowed
            1000, // minimumRequestAmountAllowed
            5000, // maximumRequestAmountAllowed
            5000, // minimumCampaignTarget
            1000000, // maximumCampaignTarget
            604800, // maxDeadlineExtension
            86400, // minDeadlineExtension
            86400, // minRequestDuration
            604800, // maxRequestDuration
            80, // reviewThresholdMark
            51, // requestFinalizationThreshold
            51 // reportThresholdMark
        ];

        for (uint256 index = 0; index < transactionConfigs.length; index++) {
            campaignTransactionConfigList.push(transactionConfigs[index]);
            approvedCampaignTransactionConfig[transactionConfigs[index]] = true;
            campaignTransactionConfig[
                transactionConfigs[index]
            ] = defaultTransactionConfigValues[index];
        }

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

    /**
     * @dev        Set Factory controlled values dictating how campaigns should run
     * @param      _wallet                          Address where all revenue gets deposited
     * @param      _campaignImplementation          Address of base contract to deploy minimal proxies to campaigns
     * @param      _campaignRewardsImplementation   Address of base contract to deploy minimal proxies to campaign rewards
     */
    function setFactoryConfig(
        address payable _wallet,
        Campaign _campaignImplementation,
        CampaignReward _campaignRewardsImplementation,
        CampaignRequest _campaignRequestsImplementation,
        CampaignVote _campaignVotesImplementation
    ) external onlyAdmin {
        require(address(_wallet) != address(0));
        require(address(_campaignImplementation) != address(0));
        require(address(_campaignRewardsImplementation) != address(0));

        factoryWallet = _wallet;
        campaignImplementation = address(_campaignImplementation);
        campaignRewardsImplementation = address(_campaignRewardsImplementation);
        campaignRequestsImplementation = address(
            _campaignRequestsImplementation
        );
        campaignVotesImplementation = address(_campaignVotesImplementation);

        emit FactoryConfigUpdated(
            _wallet,
            address(_campaignImplementation),
            address(_campaignRewardsImplementation),
            address(_campaignRequestsImplementation),
            address(_campaignVotesImplementation)
        );
    }

    /**
     * @dev        Adds a new transaction setting
     * @param      _prop    Setting Key
     */
    function addFactoryTransactionConfig(string memory _prop)
        external
        onlyAdmin
    {
        require(!approvedCampaignTransactionConfig[_prop]);
        campaignTransactionConfigList.push(_prop);
        approvedCampaignTransactionConfig[_prop] = true;
    }

    /**
     * @dev        Set Factory controlled values dictating how campaign deployments should run
     * @param      _prop    Setting Key
     * @param      _value   Setting Value
     */
    function setCampaignTransactionConfig(string memory _prop, uint256 _value)
        external
        onlyAdmin
    {
        require(approvedCampaignTransactionConfig[_prop]);
        campaignTransactionConfig[_prop] = _value;

        emit CampaignTransactionConfigUpdated(_prop, _value);
    }

    /**
     * @dev        Sets default commission on all request finalization
     * @param      _numerator    Fraction Fee percentage on request finalization
     * @param      _denominator  Fraction Fee percentage on request finalization
     */
    function setDefaultCommission(uint256 _numerator, uint256 _denominator)
        external
        onlyAdmin
    {
        DecimalMath.UFixed memory _commission = DecimalMath.divd(
            DecimalMath.toUFixed(_numerator),
            DecimalMath.toUFixed(_denominator)
        );
        campaignTransactionConfig["defaultCommission"] = _commission.value;

        emit CampaignDefaultCommissionUpdated(_commission.value);
    }

    /**
     * @dev        Sets commission per category basis
     * @param      _categoryId   ID of category
     * @param      _numerator    Fraction Fee percentage on request finalization in campaign per category `defaultCommission` will be utilized if value is `0`
     * @param      _denominator  Fraction Fee percentage on request finalization in campaign per category `defaultCommission` will be utilized if value is `0`
     */
    function setCategoryCommission(
        uint256 _categoryId,
        uint256 _numerator,
        uint256 _denominator
    ) external onlyAdmin {
        require(campaignCategories[_categoryId].exists);

        DecimalMath.UFixed memory _commission = DecimalMath.divd(
            DecimalMath.toUFixed(_numerator),
            DecimalMath.toUFixed(_denominator)
        );
        categoryCommission[_categoryId] = _commission.value;
        campaignCategories[_categoryId].updatedAt = block.timestamp;

        emit CategoryCommissionUpdated(_categoryId, _commission.value);
    }

    /**
     * @dev        Adds a token that needs approval before being accepted
     * @param      _token  Address of the token
     */
    function addToken(address _token) external onlyAdmin {
        require(!tokenInList[_token]);

        tokenInList[_token] = true;

        emit TokenAdded(_token);
    }

    /**
     * @dev        Sets if a token is accepted or not provided it's in the list of token
     * @param      _token   Address of the token
     * @param      _state   Indicates if the token is approved or not
     */
    function toggleAcceptedToken(address _token, bool _state)
        external
        onlyAdmin
    {
        require(tokenInList[_token]);
        tokensApproved[_token] = _state;

        emit TokenApproval(_token, _state);
    }

    /**
     * @dev        Checks if a user can manage a campaign. Called but not restricted to external campaign proxies
     * @param      _user    Address of user
     */
    function canManageCampaigns(address _user) public view returns (bool) {
        return hasRole(MANAGE_CAMPAIGNS, _user);
    }

    /**
     * @dev        Retrieves campaign commission fees. Restricted to campaign owner.
     * @param      _amount      Amount transfered and collected by factory from campaign request finalization
     * @param      _campaign    Address of campaign instance
     */
    function receiveCampaignCommission(Campaign _campaign, uint256 _amount)
        external
        onlyRegisteredCampaigns(campaignToID[address(_campaign)])
    {
        campaignRevenueFromCommissions[
            campaignToID[address(_campaign)]
        ] = campaignRevenueFromCommissions[campaignToID[address(_campaign)]]
            .add(_amount);
        factoryRevenue = factoryRevenue.add(_amount);
    }

    /// @dev Keep track of user addresses. sybil resistance purpose
    function signUp() public whenNotPaused {
        users.push(User(msg.sender, block.timestamp, 0, false, true));
        userID[msg.sender] = users.length.sub(1);
        userCount = userCount.add(1);

        emit UserAdded(users.length.sub(1));
    }

    /**
     * @dev        Ensures user specified is verified
     * @param      _user    Address of user
     */
    function userIsVerified(address _user) public view returns (bool) {
        return
            users[userID[_user]].userAddress == _user &&
            users[userID[_user]].verified;
    }

    /**
     * @dev        Trustees are people the user can add to help recover their account in the case they lose access to ther wallets
     * @param      _trustee    Address of the trustee, must be a verified user
     */
    function addTrustee(address _trustee) external whenNotPaused {
        require(userIsVerified(msg.sender), "unverified user");
        require(userIsVerified(_trustee), "unverified trustee");
        require(userTrusteeCount[msg.sender] <= 6, "trustees exhausted");

        isUserTrustee[msg.sender][_trustee] = true;
        trustees.push(Trust(_trustee, msg.sender, block.timestamp, true));
        userTrusteeCount[msg.sender] = userTrusteeCount[msg.sender].add(1);

        emit TrusteeAdded(trustees.length.sub(1), _trustee);
    }

    /**
     * @dev        Removes a trustee from users list of trustees
     * @param      _trusteeId    Address of the trustee
     */
    function removeTrustee(uint256 _trusteeId) external whenNotPaused {
        Trust storage trustee = trustees[_trusteeId];

        require(msg.sender == trustee.trustor, "not owner of trust");
        require(userIsVerified(msg.sender), "unverified user");

        isUserTrustee[msg.sender][trustee.trustee] = false;
        userTrusteeCount[msg.sender] = userTrusteeCount[msg.sender].sub(1);
        delete trustees[_trusteeId];

        emit TrusteeRemoved(_trusteeId, trustee.trustee);
    }

    /**
     * @dev        Approves or disapproves a user
     * @param      _userId      ID of the user
     * @param      _approval    Indicates if the user will be approved or not
     */
    function toggleUserApproval(uint256 _userId, bool _approval)
        external
        onlyManager(MANAGE_USERS)
        whenNotPaused
    {
        require(users[_userId].exists);
        users[_userId].verified = _approval;
        users[_userId].updatedAt = block.timestamp;

        emit UserApproval(_userId, users[_userId].userAddress, _approval);
    }

    /**
     * @dev        Deploys and tracks a new campagign
     * @param      _categoryId    ID of category campaign deployer specifies
     */
    function createCampaign(uint256 _categoryId, bool _approved)
        external
        whenNotPaused
    {
        // check `_categoryId` exists and active
        require(
            campaignCategories[_categoryId].exists &&
                campaignCategories[_categoryId].active
        );

        address campaign = ClonesUpgradeable.clone(campaignImplementation);
        address campaignRewards = ClonesUpgradeable.clone(
            campaignRewardsImplementation
        );
        address campaignRequests = ClonesUpgradeable.clone(
            campaignRequestsImplementation
        );
        address campaignVotes = ClonesUpgradeable.clone(
            campaignVotesImplementation
        );

        CampaignInfo memory campaignInfo = CampaignInfo({
            campaign: campaign,
            category: _categoryId,
            owner: msg.sender,
            createdAt: block.timestamp,
            updatedAt: 0,
            approved: _approved
        });
        deployedCampaigns.push(campaignInfo);
        campaignToOwner[address(campaign)] = msg.sender; // keep track of campaign owner

        uint256 campaignId = deployedCampaigns.length.sub(1);
        campaignToID[address(campaign)] = campaignId;

        campaignCategories[_categoryId].campaignCount = campaignCategories[
            _categoryId
        ].campaignCount.add(1);
        campaignCount = campaignCount.add(1);

        Campaign(campaign).__Campaign_init(
            CampaignFactory(this),
            CampaignReward(campaignRewards),
            CampaignRequest(campaignRequests),
            CampaignVote(campaignVotes),
            msg.sender,
            campaignId
        );
        CampaignReward(campaignRewards).__CampaignReward_init(
            CampaignFactory(this),
            Campaign(campaign),
            campaignId
        );
        CampaignRequest(campaignRewards).__CampaignRequest_init(
            CampaignFactory(this),
            Campaign(campaign),
            campaignId
        );
        CampaignVote(campaignRewards).__CampaignVote_init(
            CampaignFactory(this),
            Campaign(campaign),
            campaignId
        );

        emit CampaignDeployed(
            address(this),
            address(campaign),
            address(campaignRewards),
            address(campaignRequests),
            address(campaignVotes),
            _categoryId,
            _approved
        );
    }

    /**
     * @dev        Approves or disapproves a campaign. Restricted to campaign managers
     * @param      _campaignId    ID of the campaign
     * @param      _approval      Indicates if the campaign will be approved or not. Affects campaign listing and transactions
     */
    function toggleCampaignApproval(uint256 _campaignId, bool _approval)
        external
        campaignOwner(_campaignId)
        whenNotPaused
    {
        deployedCampaigns[_campaignId].approved = _approval;
        deployedCampaigns[_campaignId].updatedAt = block.timestamp;

        emit CampaignApproval(
            deployedCampaigns[_campaignId].campaign,
            _approval
        );
    }

    /**
     * @dev         Modifies a campaign's category.
     * @param      _campaignId      ID of the campaign
     * @param      _newCategoryId   ID of the category being switched to
     */
    function modifyCampaignCategory(uint256 _campaignId, uint256 _newCategoryId)
        external
        campaignOwner(_campaignId)
        whenNotPaused
    {
        uint256 _oldCategoryId = deployedCampaigns[_campaignId].category;

        if (_oldCategoryId != _newCategoryId) {
            require(campaignCategories[_newCategoryId].exists);

            deployedCampaigns[_campaignId].category = _newCategoryId;
            campaignCategories[_oldCategoryId]
                .campaignCount = campaignCategories[_oldCategoryId]
                .campaignCount
                .sub(1);
            campaignCategories[_newCategoryId]
                .campaignCount = campaignCategories[_newCategoryId]
                .campaignCount
                .add(1);

            deployedCampaigns[_campaignId].updatedAt = block.timestamp;

            emit CampaignCategoryChange(
                deployedCampaigns[_campaignId].campaign,
                _newCategoryId
            );
        }
    }

    /**
     * @dev        Creates a category
     * @param      _active   Indicates if a category is active allowing for campaigns to be assigned to it
     */
    function createCategory(bool _active)
        external
        onlyManager(MANAGE_CATEGORIES)
        whenNotPaused
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

        categoryCommission[campaignCategories.length.sub(1)] = 0;

        emit CategoryAdded(campaignCategories.length.sub(1), _active);
    }

    /**
     * @dev        Modifies details about a category
     * @param      _categoryId   ID of the category
     * @param      _active       Indicates if a category is active allowing for campaigns to be assigned to it
     */
    function modifyCategory(uint256 _categoryId, bool _active)
        external
        onlyManager(MANAGE_CATEGORIES)
        whenNotPaused
    {
        require(campaignCategories[_categoryId].exists);

        campaignCategories[_categoryId].active = _active;
        campaignCategories[_categoryId].updatedAt = block.timestamp;

        emit CategoryModified(_categoryId, _active);
    }

    /// @dev Unpauses the factory, transactions in the factory resumes per usual
    function unpauseCampaign() external whenPaused onlyAdmin {
        _unpause();
    }

    /// @dev Pauses the factory, halts all transactions in the factory
    function pauseCampaign() external whenNotPaused onlyAdmin {
        _pause();
    }
}
