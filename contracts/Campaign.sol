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
import "./utils/CampaignCommission.sol";

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
    event CampaignIDset(uint256 indexed campaignId);
    event CampaignDetailsModified(
        uint256 indexed campaignId,
        uint256 minimumContribution,
        uint256 deadline,
        uint256 goalType,
        address token
    );
    event CampaignGoalTypeChange(uint256 indexed campaignId, uint256 goalType);
    event CampaignDeadlineExtended(uint256 indexed campaignId, uint256 time);

    /// @dev `Contribution Events`
    event ContributionMade(
        uint256 indexed campaignId,
        uint256 userId,
        uint256 amount
    );
    event ContributionWithdrawn(
        uint256 indexed campaignId,
        uint256 userId,
        uint256 amount
    );
    event TargetMet(uint256 indexed campaignId, uint256 amount);

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

    /// @dev `Rwardee Events`
    event RewardeedAdded(
        uint256 indexed rewardId,
        uint256 campaignId,
        uint256 user,
        uint256 amount
    );
    event RewardeeApproval(
        uint256 indexed rewardeeId,
        uint256 campaignId,
        bool status
    );

    /// @dev `Vote Events`
    event Voted(uint256 requestId);

    /// @dev `Campaign State Events`
    event CampaignStateChange(uint256 campaignId, CAMPAIGN_STATE state);

    CampaignFactoryInterface campaignFactoryContract;

    address public root;
    address public acceptedToken;

    /// @dev `Request`
    struct Request {
        address payable recepient;
        bool complete;
        uint256 value;
        uint256 approvalCount;
        uint256 disapprovalCount;
        mapping(address => bool) approvals;
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
    uint256 public maximumContribution;
    uint256 public approversCount;
    uint256 public target;
    uint256 public deadline;
    uint256 public deadlineSetTimes;
    uint256 public reviewCount;
    bool public requestOngoing;
    mapping(address => bool) public approvers;
    mapping(address => uint256) public userTotalContribution;

    /// @dev Ensures caller is only factory
    modifier onlyFactory() {
        require(campaignFactoryContract.canManageCampaigns(msg.sender));
        _;
    }

    /// @dev Ensures caller is factory or campaign owner
    modifier adminOrFactory() {
        require(
            campaignFactoryContract.canManageCampaigns(msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        );
        _;
    }

    /// @dev Ensures the campaign is set to active by campaign owner and approved by factory
    modifier campaignIsActive() {
        bool campaignIsEnabled;
        bool campaignIsApproved;

        (, , campaignIsEnabled, campaignIsApproved) = campaignFactoryContract
        .deployedCampaigns(campaignID);

        require(campaignIsApproved && campaignIsEnabled);
        _;
    }

    /// @dev Ensures campaign isn't approved by factory. Applies unless campaign manager from factory
    modifier campaignIsNotApproved() {
        bool campaignIsApproved;
        (, , , campaignIsApproved) = campaignFactoryContract.deployedCampaigns(
            campaignID
        );

        require(
            !campaignIsApproved &&
                !campaignFactoryContract.canManageCampaigns(msg.sender)
        );
        _;
    }

    /// @dev Ensures a user is verified
    modifier userIsVerified(address _user) {
        bool userVerified;

        (, , , , , userVerified, ) = campaignFactoryContract.users(
            campaignFactoryContract.userID(_user)
        );
        require(userVerified);
        _;
    }

    /// @dev Ensures a user is a contributor and hasn't voted before
    modifier canApproveRequest(uint256 _requestId) {
        require(
            approvers[msg.sender] && !requests[_requestId].approvals[msg.sender]
        );
        _;
    }

    /// @dev Ensures the campaign is within it's deadline, applies only if goal type is fixed
    modifier deadlineIsUp() {
        if (goalType == GOALTYPE.FIXED) {
            require(block.timestamp <= deadline);
        }
        _;
    }

    /**
     * @dev        Constructor
     * @param      _campaignFactory     Address of factory
     * @param      _root                Address of campaign owner
     */
    function __Campaign_init(address _campaignFactory, address _root)
        public
        initializer
    {
        require(address(_root) != address(0));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        campaignFactoryContract = CampaignFactoryInterface(_campaignFactory);

        root = _root;

        campaignState = CAMPAIGN_STATE.GENESIS;
        campaignID = campaignFactoryContract.campaignToID(address(this));

        emit CampaignIDset(campaignID);

        _pause();
    }

    /**
     * @dev         Modifies campaign details while it's not approved
     * @param      _target              Contribution target of the campaign
     * @param      _minimumContribution The minimum amout required to be an approver
     * @param      _duration            How long until the campaign stops receiving contributions
     * @param      _goalType            Indicates if campaign is fixed or flexible with contributions
     * @param      _token               Address of token to be used for transactions by default
     */
    function setCampaignDetails(
        uint256 _target,
        uint256 _minimumContribution,
        uint256 _duration,
        uint256 _goalType,
        address _token
    ) external adminOrFactory campaignIsNotApproved {
        require(
            (_minimumContribution >=
                campaignFactoryContract.minimumContributionAllowed() &&
                _minimumContribution <=
                campaignFactoryContract.maximumContributionAllowed()) &&
                campaignFactoryContract.tokensApproved(_token)
        );
        target = _target;
        minimumContribution = _minimumContribution;
        deadline = _duration;
        goalType = GOALTYPE(_goalType);
        acceptedToken = _token;

        emit CampaignDetailsModified(
            campaignID,
            _minimumContribution,
            _duration,
            _goalType,
            _token
        );
    }

    /**
     * @dev        Modifies campaign's goal type provided deadline is expired
     * @param      _type    Indicates if campaign is fixed or flexible with contributions
     */
    function setGoalType(uint256 _type)
        external
        adminOrFactory
        campaignIsActive
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
    {
        require(
            (block.timestamp > deadline &&
                deadlineSetTimes <=
                campaignFactoryContract.deadlineStrikesAllowed()) &&
                _time <= campaignFactoryContract.maxDeadline() &&
                _time >= campaignFactoryContract.minDeadline()
        ); // ensure time exceeds 7 days and less than a day

        deadline = _time;

        // limit ability to increase deadlines
        deadlineSetTimes = deadlineSetTimes.add(1);

        emit CampaignDeadlineExtended(campaignID, _time);
    }

    /// @dev Resets the number of times campaign manager has extended deadlines
    function resetDeadlineSetTimes()
        external
        adminOrFactory
        campaignIsActive
        whenNotPaused
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
    ) external adminOrFactory campaignIsActive whenNotPaused {
        require(
            _value > campaignFactoryContract.minimumContributionAllowed() &&
                _value < campaignFactoryContract.maximumContributionAllowed()
        );
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
    ) external adminOrFactory campaignIsActive whenNotPaused {
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
    {
        require(rewards[_rewardId].exists);

        delete rewards[_rewardId];

        emit RewardDestroyed(_rewardId);
    }

    /**
     * @dev        Used by the campaign owner to indicate they delivered the reward to the rewardee
     * @param      _rewardeeId  ID to struct containing reward and user to be rewarded
     * @param      _status      Indicates if the delivery was successful or not
     */
    function campaignSentReward(uint256 _rewardeeId, bool _status)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        adminOrFactory
        whenNotPaused
    {
        rewardees[_rewardeeId].deliveryConfirmedByCampaign = _status;
        emit RewardeeApproval(_rewardeeId, campaignID, _status);
    }

    /**
     * @dev        Used by a user eligible for rewards to indicate they received their reward
     * @param      _rewardeeId  ID to struct containing reward and user to be rewarded
     * @param      _status      Indicates if the delivery was successful or not
     */
    function userReceivedCampaignReward(uint256 _rewardeeId, bool _status)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(rewardees[_rewardeeId].deliveryConfirmedByCampaign); // ensure campaign owner tried to confirm delivery
        require(
            rewardees[_rewardeeId].user == msg.sender &&
                userHasReward[msg.sender] &&
                approvers[msg.sender]
        );
        rewardees[_rewardeeId].deliveryConfirmedByCampaign = _status;
        emit RewardeeApproval(_rewardeeId, campaignID, _status);
    }

    /**
     * @dev        Contribute method enables a user become an approver in the campaign
     * @param      _token       Address of token to be used for transactions by default
     * @param      _rewardId    Reward unique id
     * @param      _withReward  Indicates if the user wants a reward alongside their contribution
     */
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
        returns (uint256 targetCompletionValue)
    {
        require(
            _token == acceptedToken &&
                msg.value >= minimumContribution &&
                msg.value <=
                campaignFactoryContract.maximumContributionAllowed()
        );

        // check user contribution added to current total contribution doesn't exceed target
        // if it does, calculate the amount to target completion return it back to user to change contribution value
        uint256 overheadTotalCampaignContribution = totalCampaignContribution
        .add(msg.value);

        if (
            goalType == GOALTYPE.FIXED &&
            overheadTotalCampaignContribution > totalCampaignContribution
        ) {
            //require(totalCampaignContribution < target);
            return
                overheadTotalCampaignContribution.sub(
                    totalCampaignContribution
                );
        }

        if (_withReward) {
            require(
                msg.value >= rewards[_rewardId].value &&
                    rewards[_rewardId].stock > 0 &&
                    rewards[_rewardId].exists &&
                    rewards[_rewardId].active
            );

            rewardees.push(Rewardee(_rewardId, msg.sender, false, false));
            userHasReward[msg.sender] = true;
            emit RewardeedAdded(
                _rewardId,
                campaignID,
                campaignFactoryContract.userID(msg.sender),
                msg.value
            );
        }

        _contribute();
    }

    /// @dev Private `_contribute` method implemented by `contribute()` methood
    function _contribute() private {
        approvers[msg.sender] = true;

        if (!approvers[msg.sender]) {
            approversCount = approversCount.add(1);
        }

        totalCampaignContribution = totalCampaignContribution.add(msg.value);
        userTotalContribution[msg.sender] = userTotalContribution[msg.sender]
        .add(msg.value);

        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(acceptedToken),
            msg.sender,
            address(this),
            msg.value
        );

        emit ContributionMade(
            campaignID,
            campaignFactoryContract.userID(msg.sender),
            msg.value
        );

        // keep track of when target is met
        if (totalCampaignContribution >= target) {
            emit TargetMet(campaignID, totalCampaignContribution);
        }
    }

    /**
     * @dev        Allows withdrawal of balance left after requests, called only by user
     * @param      _amount    Amount requested to be withdrawn from contributions
     * @param      _wallet    Address where amount is delivered
     */
    function withdrawOwnContribution(uint256 _amount, address payable _wallet)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        _withdrawContribution(msg.sender, _wallet, _amount);
    }

    /**
     * @dev        Allows withdrawal of balance by factory on behalf of a user. 
                   Cases where users wallet is compromised
     * @param      _user      User whose funds are being requested
     * @param      _amount    Amount requested to be withdrawn from contributions
     * @param      _wallet    Address where amount is delivered
     */
    function withdrawContributionForUser(
        address _user,
        uint256 _amount,
        address payable _wallet
    ) external onlyFactory nonReentrant whenNotPaused {
        _withdrawContribution(_user, _wallet, _amount);
    }

    /**
     * @dev        Private `_withdrawContribution` implemented by `withdrawOwnContribution` and `withdrawContributionForUser`
     * @param      _user      User whose funds are being requested
     * @param      _wallet    Address where amount is delivered
     * @param      _amount    Amount requested to be withdrawn from contributions
     */
    function _withdrawContribution(
        address _user,
        address _wallet,
        uint256 _amount
    ) private {
        require(totalCampaignContribution < target); // pledge collection ongoing
        // check if person is a contributor
        require(
            approvers[_user] &&
                _amount <= userTotalContribution[_user] &&
                address(_wallet) != address(0)
        );

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

        // userBalance[_user] = userBalance[_user].sub(_amount);
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

        emit ContributionWithdrawn(
            campaignID,
            campaignFactoryContract.userID(_user),
            _amount
        );
    }

    /**
     * @dev        Creates a formal request to withdraw funds from user contributions called by the campagn manager or factory
                   Restricted unless target is met and deadline is expired
     * @param      _recipient   Address where requested funds are deposited
     * @param      _value       Amount being requested by the campaign manager
     */
    function createRequest(address payable _recipient, uint256 _value)
        external
        adminOrFactory
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
    {
        uint256 factoryPercentFee = CampaignCommission.factoryPercentFee(
            campaignFactoryContract,
            campaignID
        );
        require(totalCampaignContribution >= target); // target is acheived
        require(_value.mul(factoryPercentFee) >= 10000); // ensure request above minimum

        // before creating a new request all previous request should be complete
        require(!requestOngoing && address(_recipient) != address(0));

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

    /**
     * @dev        Approvers only method which approves spending request issued by the campaign manager or factory
     * @param      _requestId   ID of request being voted on
     */
    function voteOnRequest(uint256 _requestId)
        external
        campaignIsActive
        canApproveRequest(_requestId)
        userIsVerified(msg.sender)
        whenNotPaused
    {
        requests[_requestId].approvals[msg.sender] = true;

        requests[_requestId].approvalCount = requests[_requestId]
        .approvalCount
        .add(1);

        emit Voted(_requestId);
    }

    /**
     * @dev        Withdrawal method called only when a request receives the right amount votes
     * @param      _requestId      ID of request being withdrawn
     */
    function finalizeRequest(uint256 _requestId)
        external
        adminOrFactory
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        Request storage request = requests[_requestId];
        require(
            request.approvalCount > (approversCount.div(2)) && !request.complete
        );

        uint256 factoryPercentFee = CampaignCommission.factoryPercentFee(
            campaignFactoryContract,
            campaignID
        );

        uint256 factoryFee = request.value.mul(factoryPercentFee).div(10000);

        uint256[2] memory payouts = [request.value.sub(factoryFee), factoryFee];
        address payable[2] memory addresses = [
            request.recepient,
            campaignFactoryContract.factoryWallet()
        ];

        request.complete = true;
        requestOngoing = false;

        campaignFactoryContract.receiveCampaignCommission(
            factoryFee,
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

        emit RequestComplete(_requestId, campaignID);
    }

    /// @dev Pauses the campaign and switches `campaignState` to `REVIEW` indicating it's ready to be reviewd by it's approvers after the campaign is over
    function reviewMode()
        external
        adminOrFactory
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
    {
        // check requests is more than 1
        // check balance is 0
        // check no pending request
        // check campaign state is running
        require(
            requests.length > 1 &&
                !requestOngoing &&
                campaignState == CAMPAIGN_STATE.ONGOING
        );

        campaignState = CAMPAIGN_STATE.REVIEW;
        _pause();

        emit CampaignStateChange(campaignID, CAMPAIGN_STATE.REVIEW);
    }

    /// @dev User acknowledgement of review state enabled by the campaign owner
    function reviewCampaignPerformance()
        external
        userIsVerified(msg.sender)
        campaignIsActive
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

    /// @dev Called by campaign manager to mark the campaign as complete right after it secured enough reviews from users
    function markCampaignComplete()
        external
        userIsVerified(msg.sender)
        adminOrFactory
        campaignIsActive
        whenPaused
    {
        // check if reviewers count > 80% of approvers set campaign state to complete
        require(
            reviewCount >= approversCount.mul(80).div(100) &&
                campaignState == CAMPAIGN_STATE.REVIEW
        );
        campaignState = CAMPAIGN_STATE.COMPLETE;

        emit CampaignStateChange(campaignID, CAMPAIGN_STATE.COMPLETE);
    }

    /// @dev Changes campaign state
    function setCampaignState(uint256 _state) external onlyFactory {
        campaignState = CAMPAIGN_STATE(_state);

        emit CampaignStateChange(campaignID, CAMPAIGN_STATE(_state));
    }

    /// @dev Unpauses the campaign, transactions in the campaign resume per usual
    function unpauseCampaign() external whenPaused onlyFactory {
        _unpause();
    }

    /// @dev Pauses the campaign, it halts all transactions in the campaign
    function pauseCampaign() external whenNotPaused onlyFactory {
        _pause();
    }
}
