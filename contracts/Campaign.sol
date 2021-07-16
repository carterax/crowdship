// contracts/Campaign.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./utils/AccessControl.sol";
import "./utils/FactoryInterface.sol";

contract Campaign is
    Initializable,
    AccessControl,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    enum GOALTYPE {
        FIXED,
        FLEXIBLE
    }
    GOALTYPE public goalType;

    enum CAMPAIGN_STATE {
        GENESIS,
        ONGOING,
        REVIEW,
        COMPLETE
    }
    CAMPAIGN_STATE public campaignState;

    /// @dev `Campaign`
    event CampaignDetailsModified(
        uint256 indexed campaignId,
        uint256 minimumContribution,
        uint256 deadline,
        uint256 goalType
    );
    event CampaignTokenChanged(uint256 indexed campaignId, address token);
    event CampaignGoalTypeChange(uint256 indexed campaignId, uint256 goalType);
    event CampaignDeadlineExtended(uint256 indexed campaignId, uint256 time);

    /// @dev `Contribution Events`
    event ContributionMade(uint256 indexed campaignId, uint256 amount);
    event ContributionWithdrawn(uint256 indexed campaignId, uint256 amount);

    /// @dev `Request Events`
    event RequestAdded(
        uint256 indexed requestId,
        uint256 campaignId,
        address recipient,
        uint256 value
    );
    event RequestComplete(uint256 indexed requestId, uint256 campaignId);

    /// @dev `Reward Events`
    event RewardCreated(
        uint256 indexed rewardId,
        uint256 campaignId,
        uint256 value,
        uint256 deliveryDate,
        uint256 stock,
        bool active
    );
    event RewardModified(
        uint256 rewardId,
        uint256 campaignId,
        uint256 value,
        uint256 deliveryDate,
        uint256 stock,
        bool active
    );
    event RewardDestroyed(uint256 rewardId);
    event CampaignApprovalRequest(uint256 campaignId);

    /// @dev `Rwardee Events`
    event ContributionWithReward(
        uint256 indexed rewardId,
        uint256 campaignId,
        uint256 user,
        uint256 amount
    );

    /// @dev `Vote Events`
    event Voted(uint256 requestId, bool vote);

    /// @dev `Campaign State Events`
    event CampaignStateChange(uint256 campaignId, CAMPAIGN_STATE state);

    CampaignFactoryInterface campaignFactoryContract;

    address public root;
    address public acceptedToken;

    /// @dev `Vote`
    struct Vote {
        bool approved;
        bool voted;
        uint256 created;
    }

    /// @dev `Request`
    struct Request {
        address payable recepient;
        bool complete;
        uint256 value;
        uint256 approvalCount;
        uint256 disapprovalCount;
        mapping(address => Vote) votes;
    }
    Request[] public requests;
    uint256 public requestCount;

    /// @dev `Reward`
    struct Reward {
        uint256 value;
        uint256 deliveryDate;
        uint256 stock;
        bool exists;
        bool active;
    }
    Reward[] public rewards;

    /// @dev `Rewardee`
    struct Rewardee {
        uint256 rewardId;
        address user;
        bool deliveryConfirmedByCampaign;
        bool deliveryConfirmedByUser;
    }
    Rewardee[] public rewardees;
    mapping(address => bool) userHasReward;

    /// @dev `Review`
    struct Review {
        address user;
        uint256 rating;
        uint256 createdAt;
    }
    Review[] public reviews;
    mapping(address => bool) public reviewed;

    uint256 public campaignID;
    uint256 public totalCampaignContribution;
    uint256 public minimumContribution;
    uint256 public approversCount;
    uint256 public target;
    uint256 public deadline;
    uint256 public deadlineSetTimes;
    uint256 public reviewCount;
    bool public requestOngoing;
    mapping(address => bool) public approvers;
    mapping(address => uint256) public userTotalContribution;
    mapping(address => uint256) public userBalance;

    modifier onlyFactory() {
        require(campaignFactoryContract.canManageCampaigns(msg.sender));
        _;
    }

    modifier adminOrFactory() {
        require(
            campaignFactoryContract.canManageCampaigns(msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        );
        _;
    }

    modifier campaignIsActive() {
        bool campaignIsEnabled;
        bool campaignIsApproved;

        (, , campaignIsEnabled, campaignIsApproved) = campaignFactoryContract
        .deployedCampaigns(campaignID);

        require(campaignIsApproved && campaignIsEnabled);
        _;
    }

    modifier campaignIsNotApproved() {
        bool campaignIsApproved;
        (, , , campaignIsApproved) = campaignFactoryContract.deployedCampaigns(
            campaignID
        );

        require(!campaignIsApproved);
        _;
    }

    modifier userIsVerified(address _user) {
        bool userVerified;

        (, , , , , userVerified, ) = campaignFactoryContract.users(
            campaignFactoryContract.userID(_user)
        );
        require(userVerified);
        _;
    }

    modifier canApproveRequest(uint256 _requestId) {
        require(
            approvers[msg.sender] &&
                !requests[_requestId].votes[msg.sender].voted
        );
        _;
    }

    modifier deadlineIsUp() {
        if (goalType == GOALTYPE.FIXED) {
            require(block.timestamp <= deadline);
        }
        _;
    }

    modifier targetIsMet() {
        if (goalType == GOALTYPE.FIXED) {
            require(totalCampaignContribution == target);
        }
        _;
    }

    /// @dev constructor
    function __Campaign_init(address _campaignFactory, address _root)
        public
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        campaignFactoryContract = CampaignFactoryInterface(_campaignFactory);

        root = _root;

        campaignState = CAMPAIGN_STATE.GENESIS;
        campaignID = campaignFactoryContract.campaignToID(address(this));

        _pause();
    }

    /**
     * @notice     Modifies campaign details while it's not approved
     * @dev        Testing around
     * @param      _target              Contribution target of the campaign
     * @param      _minimumContribution The minimum amout required to be an approver
     * @param      _time                How long until the campaign stops receiving contributions
     * @param      _goalType            Indicates if campaign is fixed or flexible with contributions
     */
    function setCampaignDetails(
        uint256 _target,
        uint256 _minimumContribution,
        uint256 _time,
        uint256 _goalType
    ) external adminOrFactory campaignIsNotApproved nonReentrant {
        target = _target;
        minimumContribution = _minimumContribution;
        deadline = _time;
        goalType = GOALTYPE(_goalType);

        emit CampaignDetailsModified(
            campaignID,
            _minimumContribution,
            _time,
            _goalType
        );
    }

    /**
     * @dev        Modifies campaign's accepted token provided factory approves it
     * @param      _token   Address of token to be used for transactions
     */
    function setAcceptedToken(address _token)
        external
        adminOrFactory
        campaignIsNotApproved
        nonReentrant
    {
        require(campaignFactoryContract.tokensApproved(_token));
        acceptedToken = _token;

        emit CampaignTokenChanged(campaignID, _token);
    }

    /**
     * @dev        Modifies campaign's goal type provided deadline is expired
     * @param      _type    Indicates if campaign is fixed or flexible with contributions
     */
    function setGoalType(uint256 _type)
        external
        adminOrFactory
        campaignIsActive
        whenNotPaused
        nonReentrant
    {
        // check that deadline is expired
        require(block.timestamp > deadline);

        goalType = GOALTYPE(_type);

        emit CampaignGoalTypeChange(campaignID, _type);
    }

    /**
     * @dev        Extends campaign contribution deadline
     * @param      _time    How long until the campaign stops receiving contributions
     */
    function extendDeadline(uint256 _time)
        external
        adminOrFactory
        campaignIsActive
        whenNotPaused
        nonReentrant
    {
        require(
            block.timestamp > deadline &&
                deadlineSetTimes <=
                campaignFactoryContract.deadlineStrikesAllowed()
        );

        // check if time exceeds 7 days and less than a day
        if (
            _time <= campaignFactoryContract.maxDeadline() &&
            _time >= campaignFactoryContract.minDeadline()
        ) {
            deadline = _time;

            // limit ability to increase deadlines
            deadlineSetTimes = deadlineSetTimes.add(1);

            emit CampaignDeadlineExtended(campaignID, _time);
        }
    }

    /**
     * @dev        Resets the number of times campaign manager has extended deadlines
     */
    function resetDeadlineSetTimes()
        external
        adminOrFactory
        campaignIsActive
        whenNotPaused
        nonReentrant
    {
        deadlineSetTimes = 0;

        // FAILSAFE: hold up now cowboy!
        _pause();
    }

    /**
     * @dev        Creates rewards contributors can attain
     * @param      _value        Reward cost
     * @param      _deliveryDate Time in which reward will be deliverd to contriutors
     * @param      _stock        Quantity available for dispatch
     * @param      _active       Indicates if contributors can attain the reward
     */
    function createReward(
        uint256 _value,
        uint256 _deliveryDate,
        uint256 _stock,
        bool _active
    ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant {
        rewards.push(Reward(_value, _deliveryDate, _stock, true, _active));

        emit RewardCreated(
            rewards.length.sub(1),
            campaignID,
            _value,
            _deliveryDate,
            _stock,
            _active
        );
    }

    /**
     * @dev        Modifies a reward by id
     * @param      _id              Reward unique id
     * @param      _value           Reward cost
     * @param      _deliveryDate    Time in which reward will be deliverd to contriutors
     * @param      _stock           Quantity available for dispatch
     * @param      _active          Indicates if contributors can attain the reward
     */
    function modifyReward(
        uint256 _id,
        uint256 _value,
        uint256 _deliveryDate,
        uint256 _stock,
        bool _active
    ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant {
        require(rewards[_id].exists);
        rewards[_id].value = _value;
        rewards[_id].deliveryDate = _deliveryDate;
        rewards[_id].stock = _stock;
        rewards[_id].active = _active;

        emit RewardModified(
            _id,
            campaignID,
            _value,
            _deliveryDate,
            _stock,
            _active
        );
    }

    /**
     * @dev        Deletes a reward by id
     * @param      _rewardId    Reward unique id
     */
    function destroyReward(uint256 _rewardId)
        external
        adminOrFactory
        campaignIsActive
        whenNotPaused
        nonReentrant
    {
        require(rewards[_rewardId].exists);

        delete rewards[_rewardId];

        emit RewardDestroyed(_rewardId);
    }

    function campaignSentReward(uint256 _rewardeeId, bool _status)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        adminOrFactory
        whenNotPaused
        nonReentrant
    {
        rewardees[_rewardeeId].deliveryConfirmedByCampaign = _status;
    }

    function userReceivedCampaignReward(uint256 _rewardeeId, bool _status)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        require(
            rewardees[_rewardeeId].user == msg.sender &&
                userHasReward[msg.sender] &&
                approvers[msg.sender]
        );
        rewardees[_rewardeeId].deliveryConfirmedByCampaign = _status;
    }

    function contribute(
        address _token,
        uint256 _rewardId,
        bool _withReward
    )
        external
        payable
        campaignIsActive
        userIsVerified(msg.sender)
        deadlineIsUp
        whenNotPaused
        nonReentrant
    {
        require(_token == acceptedToken);
        require(msg.value >= minimumContribution);

        if (_withReward) {
            require(
                rewards[_rewardId].value >= msg.value &&
                    rewards[_rewardId].stock > 0 &&
                    rewards[_rewardId].exists &&
                    rewards[_rewardId].active
            );

            rewardees.push(Rewardee(_rewardId, msg.sender, false, false));
            userHasReward[msg.sender] = true;
            emit ContributionWithReward(
                _rewardId,
                campaignID,
                campaignFactoryContract.userID(msg.sender),
                msg.value
            );
        }

        _contribute();
    }

    function _contribute() private {
        approvers[msg.sender] = true;

        if (!approvers[msg.sender]) {
            approversCount = approversCount.add(1);
        }

        totalCampaignContribution = totalCampaignContribution.add(msg.value);
        userTotalContribution[msg.sender] = userTotalContribution[msg.sender]
        .add(msg.value);
        userBalance[msg.sender] = userBalance[msg.sender].add(msg.value);
        campaignFactoryContract.addCampaignToUserHistory(address(this)); // emit event in factory
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(acceptedToken),
            msg.sender,
            address(this),
            msg.value
        );

        emit ContributionMade(campaignID, msg.value);
    }

    function withdrawOwnContribution(uint256 _amount, address payable _wallet)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        withdrawContribution(msg.sender, _wallet, _amount);
    }

    function withdrawContributionForUser(
        address _user,
        uint256 _amount,
        address payable _wallet
    ) external onlyFactory nonReentrant whenNotPaused {
        withdrawContribution(_user, _wallet, _amount);
    }

    function withdrawContribution(
        address _user,
        address _wallet,
        uint256 _amount
    ) private {
        // check if person is a contributor
        require(approvers[_user] && _amount <= userBalance[_user]);

        // no longer eligible for any reward
        if (userHasReward[_user]) {
            userHasReward[_user] = false;
        }

        // mark user as a non contributor
        approvers[_user] = false;

        // reduce approvers count
        approversCount = approversCount.sub(1);

        // decrement total contributions to campaign
        totalCampaignContribution = totalCampaignContribution.sub(_amount);

        userBalance[_user] = userBalance[_user].sub(_amount);
        userTotalContribution[_user] = userTotalContribution[_user].sub(
            _amount
        );

        // transfer to _user
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(acceptedToken),
            address(this),
            _wallet,
            _amount
        );

        emit ContributionWithdrawn(campaignID, _amount);
    }

    function createRequest(address payable _recipient, uint256 _value)
        external
        adminOrFactory
        campaignIsActive
        targetIsMet
        whenNotPaused
        userIsVerified(msg.sender)
        nonReentrant
    {
        // before creating a new request all previous request should be complete
        require(!requestOngoing);

        Request storage request = requests[requests.length.add(1)];
        request.recepient = _recipient;
        request.complete = false;
        request.value = _value;
        request.approvalCount = 0;

        requestCount = requestCount.add(1);
        requestOngoing = true;

        emit RequestAdded(
            requests.length.sub(1),
            campaignID,
            _recipient,
            _value
        );
    }

    function voteOnRequest(uint256 _requestId, bool _vote)
        external
        campaignIsActive
        canApproveRequest(_requestId)
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        requests[_requestId].votes[msg.sender].approved = _vote;
        requests[_requestId].votes[msg.sender].voted = true;
        requests[_requestId].votes[msg.sender].created = block.timestamp;

        // determine user % holdings in the pool
        uint256 percentageHolding = userTotalContribution[msg.sender]
        .div(totalCampaignContribution)
        .mul(100);

        // subtract % holding * request value from user total balance
        userBalance[msg.sender] = userTotalContribution[msg.sender].sub(
            percentageHolding.mul(requests[_requestId].value).div(100)
        );

        if (_vote) {
            requests[_requestId].approvalCount = requests[_requestId]
            .approvalCount
            .add(1);
        } else {
            requests[_requestId].disapprovalCount = requests[_requestId]
            .disapprovalCount
            .add(1);
        }

        emit Voted(_requestId, _vote);
    }

    function finalizeRequest(uint256 _id)
        external
        adminOrFactory
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        Request storage request = requests[_id];
        require(
            request.approvalCount > (approversCount.div(2)) &&
                !request.complete &&
                request.recepient != address(0)
        );

        // get factory cut
        uint256 campaignCategory;
        uint256 percentCommission;

        (, campaignCategory, , ) = campaignFactoryContract.deployedCampaigns(
            campaignID
        );
        percentCommission = campaignFactoryContract.categoryCommission(
            campaignCategory
        );

        if (percentCommission == 0) {
            percentCommission = campaignFactoryContract.defaultCommission();
        }

        uint256 factoryCommission = request.value.sub(
            percentCommission.mul(request.value).div(100)
        );
        uint256[2] memory payouts = [
            request.value.sub(factoryCommission),
            factoryCommission
        ];
        address payable[2] memory addresses = [
            request.recepient,
            campaignFactoryContract.factoryWallet()
        ];

        request.complete = true;
        requestOngoing = false;

        campaignFactoryContract.receiveCampaignCommission(
            factoryCommission,
            address(this)
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(acceptedToken),
                address(this),
                addresses[i],
                payouts[i]
            );
        }

        emit RequestComplete(_id, campaignID);
    }

    function campaignApprovalRequest()
        external
        onlyAdmin
        userIsVerified(msg.sender)
        whenPaused
        nonReentrant
    {
        emit CampaignApprovalRequest(campaignID);
    }

    function reviewMode()
        external
        adminOrFactory
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        // check requests is more than 1
        // check balance is 0
        // check no pending request
        // check campaign state is running
        require(
            requests.length > 1 &&
                totalCampaignContribution == 0 &&
                !requestOngoing &&
                campaignState == CAMPAIGN_STATE.ONGOING
        );

        campaignState = CAMPAIGN_STATE.REVIEW;
        _pause();

        emit CampaignStateChange(campaignID, CAMPAIGN_STATE.REVIEW);
    }

    function reviewCampaignPerformance()
        external
        userIsVerified(msg.sender)
        campaignIsActive
        nonReentrant
        whenPaused
    {
        require(
            campaignState == CAMPAIGN_STATE.REVIEW &&
                !reviewed[msg.sender] &&
                approvers[msg.sender]
        );

        reviewed[msg.sender] = true;
        reviewCount = reviewCount.add(1);
    }

    function markCampaignComplete()
        external
        userIsVerified(msg.sender)
        adminOrFactory
        campaignIsActive
        whenPaused
        nonReentrant
    {
        // check if reviewers count > 80% of approvers set campaign state to complete
        require(
            reviewCount >= approversCount.mul(80).div(100) &&
                campaignState == CAMPAIGN_STATE.REVIEW
        );
        campaignState = CAMPAIGN_STATE.COMPLETE;

        emit CampaignStateChange(campaignID, CAMPAIGN_STATE.COMPLETE);
    }

    function unpauseCampaign() external whenPaused onlyFactory nonReentrant {
        _unpause();
    }

    function pauseCampaign() external whenNotPaused onlyFactory nonReentrant {
        _pause();
    }
}
