// contracts/CampaignFactory.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Campaign.sol";
import "./CampaignRewards.sol";
import "./utils/AccessControl.sol";
import "./libraries/math/DecimalMath.sol";

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
        uint256 userId,
        uint256 category,
        address sender
    );
    // event CampaignDestroyed(uint256 indexed campaignId);
    event CampaignApproval(
        uint256 indexed campaignId,
        bool approval,
        address sender
    );
    event CampaignActiveToggle(
        uint256 indexed campaignId,
        bool active,
        address sender
    );
    event CampaignCategoryChange(
        uint256 indexed campaignId,
        uint256 newCategory,
        address sender
    );
    event CampaignFeatured(
        uint256 indexed campaignId,
        uint256 featurePackageId,
        uint256 amount,
        address sender
    );
    event CampaignFeaturePaused(uint256 indexed campaignId, address sender);
    event CampaignFeatureUnpaused(
        uint256 indexed campaignId,
        uint256 timeLeft,
        address sender
    );
    // event CampaignApprovalRequest(uint256 campaignId);

    /// @dev `Token Events`
    event TokenAdded(address indexed token, address sender);
    event TokenApproval(address indexed token, bool state, address sender);
    event TokenRemoved(uint256 indexed tokenId, address token, address sender);

    /// @dev `User Events`
    event UserAdded(uint256 indexed userId, address userAddress);
    event UserModified(uint256 indexed userId, address sender);
    event UserApproval(uint256 indexed userId, bool approval, address sender);
    event UserRemoved(uint256 indexed userId, address sender);
    // event UserCampaignDataTransferRequest(
    //     uint256 indexed campaignId,
    //     address oldAddress,
    //     address newAddress
    // );
    // event UserRequestCountModified(address indexed user, uint256 count);

    /// @dev `Category Events`
    event CategoryAdded(
        uint256 indexed categoryId,
        bool active,
        address sender
    );
    event CategoryModified(
        uint256 indexed categoryId,
        bool active,
        address sender
    );
    // event CategoryDestroyed(uint256 indexed categoryId);

    /// @dev `Feature Package Events`
    event FeaturePackageAdded(
        uint256 indexed packageId,
        uint256 cost,
        uint256 time,
        address sender
    );
    event FeaturePackageModified(
        uint256 indexed packageId,
        uint256 cost,
        uint256 time,
        address sender
    );
    event FeaturePackageDestroyed(uint256 indexed packageId, address sender);

    /// @dev Settings
    address public root;
    address payable public factoryWallet;
    address public campaignImplementation;
    address public campaignRewardsImplementation;
    address[] public tokenList;
    string[] public campaignTransactionConfigList;
    mapping(string => bool) public approvedcampaignTransactionConfig;
    mapping(string => uint256) public campaignTransactionConfig;
    mapping(uint256 => uint256) public categoryCommission;
    mapping(address => bool) public tokenInList;
    mapping(address => bool) public tokensApproved;

    /// @dev Revenue
    uint256 public factoryRevenue; // total from all activities (campaignRevenueFromCommissions + campaignRevenueFromFeatures)
    mapping(uint256 => uint256) public campaignRevenueFromCommissions; // revenue from cuts
    mapping(uint256 => uint256) public campaignRevenueFromFeatures; // revenue from ads

    /// @dev `Campaigns`
    struct CampaignInfo {
        address campaign;
        address campaignRewards;
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
    mapping(address => address) public campaignToOwner;
    mapping(address => uint256) public campaignToID;
    mapping(uint256 => bool) public featuredCampaignIsPaused;
    mapping(uint256 => uint256) public pausedFeaturedCampaignTimeLeft;
    // mapping(uint256 => uint256) public campaignApprovalRequestCount;

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
    mapping(address => uint256) public approverTransferRequestCount;

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

    /// @dev Ensures caller is campaign owner or campaign manager
    modifier campaignOwnerOrManager(uint256 _campaignId) {
        require(
            deployedCampaigns[_campaignId].owner == msg.sender ||
                hasRole(MANAGE_CAMPAIGNS, msg.sender),
            "campaign owner or manager"
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

    /// @dev Ensures campaign exists
    modifier campaignExists(uint256 _campaignId) {
        require(deployedCampaigns[_campaignId].exists, "campaign not found");
        _;
    }

    /// @dev Ensures campaign is active and approved
    modifier campaignIsEnabled(uint256 _id) {
        require(
            deployedCampaigns[_id].approved && deployedCampaigns[_id].active,
            "campaign disabled"
        );
        _;
    }

    /// @dev Ensures user is verifed
    modifier userIsVerified(address _user) {
        require(users[userID[_user]].verified, "unverified user");
        _;
    }

    /**
     * @dev        Contructor
     * @param      _wallet     Address where all revenue gets deposited
     */
    function __CampaignFactory_init(address payable _wallet)
        public
        initializer
    {
        require(address(_wallet) != address(0));
        root = msg.sender;
        factoryWallet = _wallet;

        string[13] memory transactionConfigs = [
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
            "reviewThresholdMark"
        ];

        for (uint256 index = 0; index < transactionConfigs.length; index++) {
            campaignTransactionConfigList.push(transactionConfigs[index]);
            approvedcampaignTransactionConfig[transactionConfigs[index]] = true;
        }

        campaignTransactionConfig["defaultCommission"] = 0;

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
        CampaignRewards _campaignRewardsImplementation
    ) external onlyAdmin {
        require(address(_wallet) != address(0));
        require(address(_campaignImplementation) != address(0));
        require(address(_campaignRewardsImplementation) != address(0));

        factoryWallet = _wallet;
        campaignImplementation = address(_campaignImplementation);
        campaignRewardsImplementation = address(_campaignRewardsImplementation);
    }

    /**
     * @dev        Adds a new transaction setting
     * @param      _prop    Setting Key
     */
    function addFactoryTransactionConfig(string memory _prop)
        external
        onlyAdmin
    {
        require(!approvedcampaignTransactionConfig[_prop]);
        campaignTransactionConfigList.push(_prop);
        approvedcampaignTransactionConfig[_prop] = true;
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
        require(approvedcampaignTransactionConfig[_prop]);
        campaignTransactionConfig[_prop] = _value;
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
    }

    /**
     * @dev        Adds a token that needs approval before being accepted
     * @param      _token  Address of the token
     */
    function addToken(address _token) external onlyAdmin {
        require(!tokenInList[_token]);

        tokenList.push(_token);
        tokenInList[_token] = true;

        emit TokenAdded(_token, msg.sender);
    }

    /**
     * @dev        Removes a token from the list of accepted tokens and tokens in list
     * @param      _tokenId      ID of the token
     * @param      _token   Address of the token
     */
    function removeToken(uint256 _tokenId, address _token) external onlyAdmin {
        require(tokenInList[_token]);

        tokenInList[_token] = false;
        tokensApproved[_token] = false;
        delete tokenList[_tokenId];

        emit TokenRemoved(_tokenId, _token, msg.sender);
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

        emit TokenApproval(_token, _state, msg.sender);
    }

    /**
     * @dev        Add an account to the role. Restricted to admins.
     * @param      _account Address of user being assigned role
     * @param      _role   Role being assigned
     */
    function addRole(address _account, bytes32 _role) public virtual onlyAdmin {
        grantRole(_role, _account);
    }

    /**
     * @dev        Remove an account from the role. Restricted to admins.
     * @param      _account Address of user whose role is being removed
     * @param      _role   Role being removed
     */
    function removeRole(address _account, bytes32 _role)
        public
        virtual
        onlyAdmin
    {
        revokeRole(_role, _account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
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
        campaignIsEnabled(campaignToID[address(_campaign)])
        campaignExists(campaignToID[address(_campaign)])
    {
        campaignRevenueFromCommissions[
            campaignToID[address(_campaign)]
        ] = campaignRevenueFromCommissions[campaignToID[address(_campaign)]]
            .add(_amount);
        factoryRevenue = factoryRevenue.add(_amount);
    }

    /// @dev Keep track of user addresses. KYC purpose
    function signUp() public whenNotPaused {
        users.push(User(msg.sender, block.timestamp, 0, false, true));
        userID[msg.sender] = users.length.sub(1);
        userCount = userCount.add(1);

        emit UserAdded(users.length.sub(1), msg.sender);
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

        emit UserApproval(_userId, _approval, msg.sender);
    }

    /**
     * @dev        Deletes a user
     * @param      _userId  ID of the user
     */
    function destroyUser(uint256 _userId)
        external
        onlyManager(MANAGE_USERS)
        whenNotPaused
    {
        User storage user = users[_userId];
        require(user.exists);
        delete users[_userId];

        emit UserRemoved(_userId, msg.sender);
    }

    /**
     * @dev        Deploys and tracks a new campagign
     * @param      _categoryId    ID of category campaign deployer specifies
     */
    function createCampaign(uint256 _categoryId)
        external
        userIsVerified(msg.sender)
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

        CampaignInfo memory campaignInfo = CampaignInfo({
            campaign: campaign,
            campaignRewards: campaignRewards,
            category: _categoryId,
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

        campaignCategories[_categoryId].campaignCount = campaignCategories[
            _categoryId
        ].campaignCount.add(1);
        campaignCount = campaignCount.add(1);

        Campaign(campaign).__Campaign_init(CampaignFactory(this), msg.sender);
        CampaignRewards(campaignRewards).__CampaignRewards_init(
            CampaignFactory(this),
            msg.sender,
            campaignId
        );

        emit CampaignDeployed(
            campaignId,
            userID[msg.sender],
            _categoryId,
            msg.sender
        );
    }

    /**
     * @dev        Approves or disapproves a campaign. Restricted to campaign managers from factory
     * @param      _campaignId    ID of the campaign
     * @param      _approval      Indicates if the campaign will be approved or not. Affects campaign listing and transactions
     */
    function toggleCampaignApproval(uint256 _campaignId, bool _approval)
        external
        onlyManager(MANAGE_CAMPAIGNS)
        campaignExists(_campaignId)
        whenNotPaused
    {
        deployedCampaigns[_campaignId].approved = _approval;
        deployedCampaigns[_campaignId].updatedAt = block.timestamp;

        emit CampaignApproval(_campaignId, _approval, msg.sender);
    }

    /**
     * @dev        Temporal campaign deactivation. Restricted to campaign managers or campaign managers from factory
     * @param      _campaignId    ID of the campaign
     * @param      _active      Indicates if the campaign will be active or not.  Affects campaign listing and transactions
     */
    function toggleCampaignActive(uint256 _campaignId, bool _active)
        external
        userIsVerified(msg.sender)
        campaignOwnerOrManager(_campaignId)
        campaignExists(_campaignId)
        whenNotPaused
    {
        // if caller is a campaign owner
        // check campaign has approvers less than or equal to 5
        // check campaign target isn't met
        if (!canManageCampaigns(msg.sender))
            require(
                Campaign(deployedCampaigns[_campaignId].campaign)
                    .approversCount() <=
                    5 &&
                    Campaign(deployedCampaigns[_campaignId].campaign)
                        .totalCampaignContribution() <
                    Campaign(deployedCampaigns[_campaignId].campaign).target()
            );

        deployedCampaigns[_campaignId].active = _active;
        deployedCampaigns[_campaignId].updatedAt = block.timestamp;

        emit CampaignActiveToggle(_campaignId, _active, msg.sender);
    }

    /**
     * @dev         Modifies a campaign's category.
     * @param      _campaignId      ID of the campaign
     * @param      _newCategoryId   ID of the category being switched to
     */
    function modifyCampaignCategory(uint256 _campaignId, uint256 _newCategoryId)
        external
        userIsVerified(msg.sender)
        campaignOwnerOrManager(_campaignId)
        campaignExists(_campaignId)
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
                _campaignId,
                _newCategoryId,
                msg.sender
            );
        }
    }

    // /**
    //  * @dev        Called by a campaign owner seeking to be approved and ready to receive contributions
    //  * @param      _campaign    Address of campaign instance
    //  */
    // function campaignApprovalRequest(address _campaign)
    //     external
    //     onlyRegisteredCampaigns(campaignToID[address(_campaign)])
    //     campaignExists(campaignToID[address(_campaign)])
    //     userIsVerified(msg.sender)
    //     whenNotPaused
    // {
    //     uint256 _campaignId = campaignToID[address(_campaign)];
    //     require(
    //         !deployedCampaigns[_campaignId].approved &&
    //             campaignApprovalRequestCount[_campaignId] <=
    //             campaignTransactionConfig["maximumUserRequestCount"]
    //     );
    //     campaignApprovalRequestCount[
    //         _campaignId
    //     ] = campaignApprovalRequestCount[_campaignId].add(1);
    //     emit CampaignApprovalRequest(_campaignId);
    // }

    // /**
    //  * @dev        Called by a campaign approver seeking to be transferred to a new verified account
    //  * @param      _campaign    Address of campaign instance
    //  * @param      _newAddress  Address of the new user being transferred to
    //  */
    // function requestUserCampaignDataTransfer(
    //     Campaign _campaign,
    //     address _newAddress
    // ) external userIsVerified(msg.sender) whenNotPaused {
    //     require(
    //         approverTransferRequestCount[msg.sender] <=
    //             campaignTransactionConfig["maximumUserRequestCount"]
    //     );
    //     approverTransferRequestCount[msg.sender] = approverTransferRequestCount[
    //         msg.sender
    //     ].add(1);
    //     emit UserCampaignDataTransferRequest(
    //         campaignToID[address(_campaign)],
    //         msg.sender,
    //         _newAddress
    //     );
    // }

    // function setUserRequestCount(address _user, uint256 _count)
    //     external
    //     onlyManager(MANAGE_USERS)
    //     whenNotPaused
    // {
    //     approverTransferRequestCount[_user] = _count;

    //     emit UserRequestCountModified(_user, _count);
    // }

    // function setMaximumUserRequestCount(uint256 _campaignId, uint256 _count)
    //     external
    //     onlyManager(MANAGE_CAMPAIGNS)
    //     campaignExists(_campaignId)
    //     whenNotPaused
    // {
    //     require(_count <= campaignTransactionConfig["maximumUserRequestCount"]);
    //     campaignApprovalRequestCount[_campaignId] = _count;
    // }

    /**
     * @dev        Purchases time for which the specified campaign will be featured. Restricted to
     * @param      _campaignId    ID of the campaign
     * @param      _token         Address of token used to purchase feature package
     */
    function featureCampaign(
        uint256 _campaignId,
        uint256 _featurePackageId,
        address _token
    )
        external
        payable
        campaignOwnerOrManager(_campaignId)
        campaignExists(_campaignId)
        campaignIsEnabled(_campaignId)
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        require(tokensApproved[_token], "disapproved token");
        require(featurePackages[_featurePackageId].exists, "package not found");
        require(
            msg.value >= featurePackages[_featurePackageId].cost,
            "price exceeds amount"
        );

        // update campaign revenue to factory
        factoryRevenue = factoryRevenue.add(msg.value);

        // update campaign revenue from ads
        campaignRevenueFromFeatures[_campaignId] = campaignRevenueFromFeatures[
            _campaignId
        ].add(msg.value);

        // update featuredFor for time specified in the selected feature package
        deployedCampaigns[_campaignId].featureFor = deployedCampaigns[
            _campaignId
        ].featureFor.add(featurePackages[_featurePackageId].time).add(
                block.timestamp
            );

        deployedCampaigns[_campaignId].updatedAt = block.timestamp;

        // transfer funds to factory wallet
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(_token),
            msg.sender,
            factoryWallet,
            msg.value
        );

        emit CampaignFeatured(
            _campaignId,
            _featurePackageId,
            msg.value,
            msg.sender
        );
    }

    /**
     * @dev        Pauses campaign feature time storing what's left for later use. Restricted to campaign owner or manager
     * @param      _campaignId   ID of the campaign
     */
    function pauseCampaignFeatured(uint256 _campaignId)
        external
        campaignOwnerOrManager(_campaignId)
        campaignExists(_campaignId)
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(
            deployedCampaigns[_campaignId].featureFor >= block.timestamp,
            "campaign feature expired"
        ); // check time in campaign feature hasn't expired
        require(
            !featuredCampaignIsPaused[_campaignId],
            "campaign feature already paused"
        ); // make sure campaign feature isn't paused

        // time in campaign currently - current time
        pausedFeaturedCampaignTimeLeft[_campaignId] = deployedCampaigns[
            _campaignId
        ].featureFor.sub(block.timestamp);

        featuredCampaignIsPaused[_campaignId] = true;

        emit CampaignFeaturePaused(_campaignId, msg.sender);
    }

    /**
     * @dev        Resumes campaign feature time
     * @param      _campaignId   ID of the campaign
     */
    function unpauseCampaignFeatured(uint256 _campaignId)
        external
        campaignOwnerOrManager(_campaignId)
        campaignExists(_campaignId)
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(featuredCampaignIsPaused[_campaignId]); // make sure campaign feature is paused

        featuredCampaignIsPaused[_campaignId] = false;

        deployedCampaigns[_campaignId].featureFor = deployedCampaigns[
            _campaignId
        ].featureFor.add(pausedFeaturedCampaignTimeLeft[_campaignId]); // add time left after pause

        // we don't owe you no more
        pausedFeaturedCampaignTimeLeft[_campaignId] = 0;

        emit CampaignFeatureUnpaused(
            _campaignId,
            pausedFeaturedCampaignTimeLeft[_campaignId],
            msg.sender
        );
    }

    // /**
    //  * @dev        Deletes a campaign
    //  * @param      _campaignId   ID of campaign
    //  */
    // function destroyCampaign(uint256 _campaignId)
    //     external
    //     onlyManager(MANAGE_CAMPAIGNS)
    //     campaignExists(_campaignId)
    //     whenNotPaused
    // {
    //     // delete the campaign from array
    //     delete deployedCampaigns[_campaignId];

    //     // emit event
    //     emit CampaignDestroyed(_campaignId);
    // }

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

        emit CategoryAdded(
            campaignCategories.length.sub(1),
            _active,
            msg.sender
        );
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

        emit CategoryModified(_categoryId, _active, msg.sender);
    }

    // /**
    //  * @dev        Deletes a category
    //  * @param      _categoryId   ID of category
    //  */
    // function destroyCategory(uint256 _categoryId)
    //     external
    //     onlyManager(MANAGE_CATEGORIES)
    //     whenNotPaused
    // {
    //     // check if category exists
    //     require(campaignCategories[_categoryId].exists);

    //     // delete the category from `campaignCategories`
    //     delete campaignCategories[_categoryId];

    //     emit CategoryDestroyed(_categoryId);
    // }

    /**
     * @dev        Creates a feature package purchased by campaig owners to feature their campaigns
     * @param      _cost        Cost of purchasing this feature package
     * @param      _time        How long a campaign will be featured for
     */
    function createFeaturePackage(uint256 _cost, uint256 _time)
        external
        onlyAdmin
        whenNotPaused
    {
        featurePackages.push(Featured(block.timestamp, 0, _time, _cost, true));
        featurePackageCount = featurePackageCount.add(1);

        emit FeaturePackageAdded(
            featurePackages.length.sub(1),
            _cost,
            _time,
            msg.sender
        );
    }

    /**
     * @dev        Modifies details about a feature package
     * @param      _packageId   ID of feature package
     * @param      _cost        Cost of purchasing this feature package
     * @param      _time        How long a campaign will be featured for
     */
    function modifyFeaturedPackage(
        uint256 _packageId,
        uint256 _cost,
        uint256 _time
    ) external onlyAdmin whenNotPaused {
        require(featurePackages[_packageId].exists);
        featurePackages[_packageId].cost = _cost;
        featurePackages[_packageId].time = _time;
        featurePackages[_packageId].updatedAt = block.timestamp;

        emit FeaturePackageModified(_packageId, _cost, _time, msg.sender);
    }

    /**
     * @dev        Deletes a feature package
     * @param      _packageId   ID of feature package
     */
    function destroyFeaturedPackage(uint256 _packageId)
        external
        onlyAdmin
        whenNotPaused
    {
        require(featurePackages[_packageId].exists);

        delete featurePackages[_packageId];

        emit FeaturePackageDestroyed(_packageId, msg.sender);
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
