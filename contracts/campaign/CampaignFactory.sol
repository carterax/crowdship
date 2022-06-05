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

import "../libraries/math/DecimalMath.sol";

contract CampaignFactory is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    /// @dev `Factory Config Events`
    event CampaignImplementationUpdated(address indexed campaignImplementation);
    event CampaignRewardImplementationUpdated(
        address indexed campaignRewardImplementation
    );
    event CampaignRequestImplementationUpdated(
        address indexed campaignRequestImplementation
    );
    event CampaignVoteImplementationUpdated(
        address indexed campaignVoteImplementation
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
        bool privateCampaign,
        string hashedCampaignInfo
    );
    event CampaignActivation(Campaign indexed campaign, bool active);
    event CampaignPrivacyChange(
        Campaign indexed campaign,
        bool privateCampaign
    );
    event CampaignCategoryChange(
        Campaign indexed campaign,
        uint256 newCategory
    );

    /// @dev `Token Events`
    event TokenAdded(address indexed token, bool approval, string hashedToken);
    event TokenApproval(address indexed token, bool state);

    /// @dev `User Events`
    event UserAdded(address indexed userId, string hashedUser);
    event UserApproval(address indexed user, bool approval);

    /// @dev `Trustee Events`
    event TrusteeAdded(uint256 indexed trusteeId, address trusteeAddress);
    event TrusteeRemoved(uint256 indexed trusteeId, address trusteeAddress);

    /// @dev `Category Events`
    event CategoryAdded(
        uint256 indexed categoryId,
        bool active,
        string title,
        string hashedCategory
    );
    event CategoryModified(
        uint256 indexed categoryId,
        bool active,
        string title
    );

    /// @dev Settings
    address public governance;
    address public campaignFactoryAddress;
    address public campaignImplementation;
    address public campaignRewardsImplementation;
    address public campaignVotesImplementation;
    address public campaignRequestsImplementation;
    string[] public campaignTransactionConfigList;
    mapping(string => bool) public approvedCampaignTransactionConfig;
    mapping(string => uint256) public campaignTransactionConfig;
    mapping(uint256 => uint256) public categoryCommission;

    /// @dev Revenue
    uint256 public factoryRevenue; // total from all campaigns
    mapping(address => uint256) public campaignRevenueFromCommissions; // revenue from cuts

    /// @dev `Campaigns`
    struct CampaignInfo {
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 category;
        string hashedCampaignInfo;
        bool active;
        bool privateCampaign;
    }
    mapping(Campaign => CampaignInfo) public campaigns;
    uint256 public campaignCount;

    /// @dev `Categories`
    struct CampaignCategory {
        uint256 campaignCount;
        uint256 createdAt;
        uint256 updatedAt;
        string title;
        string hashedCategory;
        bool active;
        bool exists;
    }
    CampaignCategory[] public campaignCategories; // array of campaign categories
    mapping(string => bool) public categoryTitleIsTaken;
    uint256 public categoryCount;

    /// @dev `Users`
    struct User {
        uint256 joined;
        uint256 updatedAt;
        string hashedUser;
        bool verified;
    }
    mapping(address => User) public users;
    mapping(address => bool) public userExists;
    uint256 public userCount;

    /// @dev `Tokens`
    struct Token {
        address token;
        string hashedToken;
        bool approved;
    }
    mapping(address => Token) public tokens;

    /// @dev `Trustees`
    struct Trust {
        address trustee;
        address trustor;
        uint256 createdAt;
        bool isTrusted;
    }
    Trust[] public trustees;
    mapping(address => uint256) public userTrusteeCount;
    mapping(address => bool) public accountInTransit;
    mapping(address => address) public accountTransitStartedBy;

    // { trustor -> trustee -> isTrusted }
    mapping(address => mapping(address => bool)) public isUserTrustee;

    /// @dev Ensures caller is owner of contract
    modifier onlyAdmin() {
        // check is governance address
        require(governance == msg.sender, "forbidden");
        _;
    }

    /// @dev Ensures caller is campaign owner alone
    modifier campaignOwner(Campaign _campaign) {
        require(
            campaigns[_campaign].owner == msg.sender,
            "only campaign owner"
        );
        _;
    }

    /// @dev Ensures caller is a registered campaign contract from factory
    modifier onlyRegisteredCampaigns(Campaign _campaign) {
        require(address(_campaign) == msg.sender, "only campaign owner");
        _;
    }

    /**
     * @dev        Contructor
     * @param      _governance     Address where all revenue gets deposited
     */
    function __CampaignFactory_init(
        address _governance,
        address _campaignImplementation,
        address _campaignRequestImplementation,
        address _campaignVoteImplementation,
        address _campaignRewardImplementation,
        uint256[15] memory _config
    ) public initializer {
        require(_governance != address(0));
        require(_campaignImplementation != address(0));
        require(_campaignRequestImplementation != address(0));
        require(_campaignVoteImplementation != address(0));
        require(_campaignRewardImplementation != address(0));

        governance = _governance;
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
            "minDeadlineExtension",
            "maxDeadlineExtension",
            "minRequestDuration",
            "maxRequestDuration",
            "reviewThresholdMark",
            "requestFinalizationThreshold",
            "reportThresholdMark"
        ];

        for (uint256 index = 0; index < transactionConfigs.length; index++) {
            campaignTransactionConfigList.push(transactionConfigs[index]);
            approvedCampaignTransactionConfig[transactionConfigs[index]] = true;
            campaignTransactionConfig[transactionConfigs[index]] = _config[
                index
            ];
        }

        campaignImplementation = _campaignImplementation;
        campaignRequestsImplementation = _campaignRequestImplementation;
        campaignVotesImplementation = _campaignVoteImplementation;
        campaignRewardsImplementation = _campaignRewardImplementation;

        _createCategory(true, "miscellaneous", "");
    }

    /**
     * @dev        Updates campaign implementation address
     * @param      _campaignImplementation  Address of base contract to deploy minimal proxies
     */
    function setCampaignImplementation(Campaign _campaignImplementation)
        external
        onlyAdmin
    {
        require(address(_campaignImplementation) != address(0));

        campaignImplementation = address(_campaignImplementation);

        emit CampaignImplementationUpdated(address(_campaignImplementation));
    }

    /**
     * @dev        Updates campaign reward implementation address
     * @param      _campaignRewardsImplementation   Address of base contract to deploy minimal proxies
     */
    function setCampaignRewardImplementation(
        CampaignReward _campaignRewardsImplementation
    ) external onlyAdmin {
        require(address(_campaignRewardsImplementation) != address(0));

        campaignRewardsImplementation = address(_campaignRewardsImplementation);

        emit CampaignRewardImplementationUpdated(
            address(_campaignRewardsImplementation)
        );
    }

    /**
     * @dev        Updates campaign request implementation address
     * @param      _campaignRequestsImplementation   Address of base contract to deploy minimal proxies
     */
    function setCampaignRequestImplementation(
        CampaignRequest _campaignRequestsImplementation
    ) external onlyAdmin {
        require(address(_campaignRequestsImplementation) != address(0));

        campaignRequestsImplementation = address(
            _campaignRequestsImplementation
        );

        emit CampaignRequestImplementationUpdated(
            address(_campaignRequestsImplementation)
        );
    }

    /**
     * @dev        Updates campaign request implementation address
     * @param      _campaignVotesImplementation   Address of base contract to deploy minimal proxies
     */
    function setCampaignVoteImplementation(
        CampaignVote _campaignVotesImplementation
    ) external onlyAdmin {
        require(address(_campaignVotesImplementation) != address(0));

        campaignVotesImplementation = address(_campaignVotesImplementation);

        emit CampaignVoteImplementationUpdated(
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
     * @param      _token       Address of the token
     * @param      _approved    Status of token approval
     * @param      _hashedToken CID reference of the token on IPFS
     */
    function addToken(
        address _token,
        bool _approved,
        string memory _hashedToken
    ) external onlyAdmin {
        tokens[_token] = Token(_token, _hashedToken, _approved);

        emit TokenAdded(_token, _approved, _hashedToken);
    }

    /**
     * @dev        Sets if a token is accepted or not provided it's in the list of token
     * @param      _token   Address of the token
     * @param      _state   Status of token approval
     */
    function toggleAcceptedToken(address _token, bool _state)
        external
        onlyAdmin
    {
        tokens[_token].approved = _state;

        emit TokenApproval(_token, _state);
    }

    /**
     * @dev        Checks if a user can manage a campaign. Called but not restricted to external campaign proxies
     * @param      _user    Address of user
     */
    function canManageCampaigns(address _user) public view returns (bool) {
        return _user == governance;
    }

    /**
     * @dev        Retrieves campaign commission fees. Restricted to campaign owner.
     * @param      _amount      Amount transfered and collected by factory from campaign request finalization
     * @param      _campaign    Address of campaign instance
     */
    function receiveCampaignCommission(Campaign _campaign, uint256 _amount)
        external
        onlyRegisteredCampaigns(_campaign)
    {
        campaignRevenueFromCommissions[
            address(_campaign)
        ] = campaignRevenueFromCommissions[address(_campaign)].add(_amount);
        factoryRevenue = factoryRevenue.add(_amount);
    }

    /**
     * @dev        Keep track of user addresses. sybil resistance purpose
     * @param      _hashedUser  CID reference of the user on IPFS
     */
    function signUp(string memory _hashedUser) public whenNotPaused {
        require(!userExists[msg.sender], "already exists");

        users[msg.sender] = User(block.timestamp, 0, _hashedUser, false);
        userExists[msg.sender] = true;
        userCount = userCount.add(1);

        emit UserAdded(msg.sender, _hashedUser);
    }

    /**
     * @dev        Ensures user specified is verified
     * @param      _user    Address of user
     */
    function userIsVerified(address _user) public view returns (bool) {
        return users[_user].verified;
    }

    /**
     * @dev        Initiates user account transfer proces
     * @param      _user        Address of user
     * @param      _forSelf     Indicates if the transfer is made on behalf of a trustee
     */
    function initiateUserTransfer(address _user, bool _forSelf) external {
        if (_forSelf) {
            accountInTransit[msg.sender] = true;
            accountTransitStartedBy[msg.sender] = msg.sender;
        } else {
            require(isUserTrustee[_user][msg.sender], "not a trustee");

            if (!accountInTransit[_user]) {
                accountInTransit[_user] = true;
                accountTransitStartedBy[_user] = msg.sender;
            }
        }
    }

    /// @dev calls off the user account transfer process
    function deactivateAccountTransfer() external {
        if (accountInTransit[msg.sender]) {
            accountInTransit[msg.sender] = false;
            accountTransitStartedBy[msg.sender] = address(0);
        }
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
     * @param      _user        Address of the user
     * @param      _approval    Indicates if the user will be approved or not
     */
    function toggleUserApproval(address _user, bool _approval)
        external
        onlyAdmin
        whenNotPaused
    {
        users[_user].verified = _approval;
        users[_user].updatedAt = block.timestamp;

        emit UserApproval(_user, _approval);
    }

    /**
     * @dev        Deploys and tracks a new campagign
     * @param      _categoryId           ID of the category the campaign belongs to
     * @param      _privateCampaign      Indicates approval status of the campaign
     * @param      _hashedCampaignInfo   CID reference of the reward on IPFS
     */
    function createCampaign(
        uint256 _categoryId,
        bool _privateCampaign,
        string memory _hashedCampaignInfo
    ) external whenNotPaused {
        // check `_categoryId` exists and active
        require(
            campaignCategories[_categoryId].exists &&
                campaignCategories[_categoryId].active
        );

        // check user exists
        require(userExists[msg.sender], "user does not exist");

        require(campaignImplementation != address(0), "zero address");
        require(campaignRewardsImplementation != address(0), "zero address");
        require(campaignRequestsImplementation != address(0), "zero address");
        require(campaignVotesImplementation != address(0), "zero address");

        Campaign campaign = Campaign(
            ClonesUpgradeable.clone(campaignImplementation)
        );
        CampaignReward campaignRewards = CampaignReward(
            ClonesUpgradeable.clone(campaignRewardsImplementation)
        );
        CampaignRequest campaignRequests = CampaignRequest(
            ClonesUpgradeable.clone(campaignRequestsImplementation)
        );
        CampaignVote campaignVotes = CampaignVote(
            ClonesUpgradeable.clone(campaignVotesImplementation)
        );

        CampaignInfo memory campaignInfo = CampaignInfo({
            category: _categoryId,
            hashedCampaignInfo: _hashedCampaignInfo,
            owner: msg.sender,
            createdAt: block.timestamp,
            updatedAt: 0,
            active: false,
            privateCampaign: _privateCampaign
        });
        campaigns[campaign] = campaignInfo;

        campaignCategories[_categoryId].campaignCount = campaignCategories[
            _categoryId
        ].campaignCount.add(1);
        campaignCount = campaignCount.add(1);

        Campaign(campaign).__Campaign_init(
            CampaignFactory(this),
            CampaignReward(campaignRewards),
            CampaignRequest(campaignRequests),
            CampaignVote(campaignVotes),
            msg.sender
        );
        CampaignReward(campaignRewards).__CampaignReward_init(
            CampaignFactory(this),
            Campaign(campaign)
        );
        CampaignRequest(campaignRequests).__CampaignRequest_init(
            CampaignFactory(this),
            Campaign(campaign)
        );
        CampaignVote(campaignVotes).__CampaignVote_init(
            CampaignFactory(this),
            Campaign(campaign)
        );

        emit CampaignDeployed(
            address(this),
            address(campaign),
            address(campaignRewards),
            address(campaignRequests),
            address(campaignVotes),
            _categoryId,
            _privateCampaign,
            _hashedCampaignInfo
        );
    }

    /**
     * @dev        Activates a campaign. Activating a campaign simply makes the campaign available for listing 
                   on crowdship, events will be stored on thegraph activated or not, Restricted to governance
     * @param      _campaign    Address of the campaign
     */
    function toggleCampaignActivation(Campaign _campaign)
        external
        onlyAdmin
        whenNotPaused
    {
        if (campaigns[_campaign].active) {
            campaigns[_campaign].active = false;
        } else {
            campaigns[_campaign].active = true;
        }

        campaigns[_campaign].updatedAt = block.timestamp;

        emit CampaignActivation(_campaign, campaigns[_campaign].active);
    }

    /**
     * @dev        Toggles the campaign privacy setting, Restricted to campaign managers
     * @param      _campaign    Address of the campaign
     */
    function toggleCampaignPrivacy(Campaign _campaign)
        external
        campaignOwner(_campaign)
        whenNotPaused
    {
        if (campaigns[_campaign].privateCampaign) {
            campaigns[_campaign].privateCampaign = false;
        } else {
            campaigns[_campaign].privateCampaign = true;
        }

        campaigns[_campaign].updatedAt = block.timestamp;

        emit CampaignPrivacyChange(
            _campaign,
            campaigns[_campaign].privateCampaign
        );
    }

    /**
     * @dev         Modifies a campaign's category.
     * @param      _campaign        Address of the campaign
     * @param      _newCategoryId   ID of the category being switched to
     */
    function modifyCampaignCategory(Campaign _campaign, uint256 _newCategoryId)
        external
        campaignOwner(_campaign)
        whenNotPaused
    {
        uint256 _oldCategoryId = campaigns[_campaign].category;

        if (_oldCategoryId != _newCategoryId) {
            require(campaignCategories[_newCategoryId].exists);

            campaigns[_campaign].category = _newCategoryId;
            campaignCategories[_oldCategoryId]
                .campaignCount = campaignCategories[_oldCategoryId]
                .campaignCount
                .sub(1);
            campaignCategories[_newCategoryId]
                .campaignCount = campaignCategories[_newCategoryId]
                .campaignCount
                .add(1);

            campaigns[_campaign].updatedAt = block.timestamp;

            emit CampaignCategoryChange(_campaign, _newCategoryId);
        }
    }

    /**
     * @dev        Public implementation of createCategory method
     * @param      _active              Indicates if a category is active allowing for campaigns to be assigned to it
     * @param      _title               Title of the category
     * @param      _hashedCategory      CID reference of the category on IPFS
     */
    function createCategory(
        bool _active,
        string memory _title,
        string memory _hashedCategory
    ) public onlyAdmin whenNotPaused {
        _createCategory(_active, _title, _hashedCategory);
    }

    /**
     * @dev        Creates a category
     * @param      _active              Indicates if a category is active allowing for campaigns to be assigned to it
     * @param      _title               Title of the category
     * @param      _hashedCategory      CID reference of the category on IPFS
     */
    function _createCategory(
        bool _active,
        string memory _title,
        string memory _hashedCategory
    ) private whenNotPaused {
        require(!categoryTitleIsTaken[_title], "title not unique");

        // create category with `campaignCount` default to 0
        CampaignCategory memory newCategory = CampaignCategory({
            campaignCount: 0,
            createdAt: block.timestamp,
            updatedAt: 0,
            title: _title,
            active: _active,
            exists: true,
            hashedCategory: _hashedCategory
        });
        campaignCategories.push(newCategory);

        categoryCount = categoryCount.add(1);

        categoryCommission[campaignCategories.length.sub(1)] = 0;

        categoryTitleIsTaken[_title] = true;

        emit CategoryAdded(
            campaignCategories.length.sub(1),
            _active,
            _title,
            _hashedCategory
        );
    }

    /**
     * @dev        Modifies details about a category
     * @param      _categoryId         ID of the category
     * @param      _active             Indicates if a category is active allowing for campaigns to be assigned to it
     * @param      _title              Title of the category
     */
    function modifyCategory(
        uint256 _categoryId,
        bool _active,
        string memory _title
    ) external onlyAdmin whenNotPaused {
        require(campaignCategories[_categoryId].exists);

        if (
            keccak256(
                abi.encodePacked(campaignCategories[_categoryId].title)
            ) != keccak256(abi.encodePacked(_title))
        ) {
            require(!categoryTitleIsTaken[_title], "title not unique");

            campaignCategories[_categoryId].title = _title;
            categoryTitleIsTaken[_title] = true;
        }

        campaignCategories[_categoryId].active = _active;
        campaignCategories[_categoryId].updatedAt = block.timestamp;

        emit CategoryModified(_categoryId, _active, _title);
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
