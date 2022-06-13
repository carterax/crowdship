// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./CampaignFactory.sol";
import "./CampaignReward.sol";
import "./CampaignRequest.sol";
import "./CampaignVote.sol";
import "../utils/AccessControl.sol";

import "../interfaces/ICampaignFactory.sol";
import "../interfaces/ICampaignReward.sol";
import "../interfaces/ICampaignRequest.sol";
import "../interfaces/ICampaignVote.sol";

import "../libraries/contracts/CampaignFactoryLib.sol";
import "../libraries/contracts/CampaignRewardLib.sol";

import "../libraries/math/DecimalMath.sol";

contract Campaign is
    Initializable,
    AccessControl,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint8;
    using SafeMathUpgradeable for uint256;
    using DecimalMath for int256;
    using DecimalMath for uint256;

    enum GOALTYPE {
        FIXED,
        FLEXIBLE
    }
    GOALTYPE public goalType;

    enum CAMPAIGN_STATE {
        COLLECTION,
        LIVE,
        REVIEW,
        COMPLETE,
        UNSUCCESSFUL
    }
    CAMPAIGN_STATE public campaignState;

    /// @dev `Initializer Event`
    event CampaignOwnerSet(address user);

    /// @dev `Campaign Config Events`
    event CampaignOwnershipTransferred(address newOwner);
    event CampaignSettingsUpdated(
        uint256 target,
        uint256 minimumContribution,
        uint256 duration,
        uint256 goalType,
        address token,
        bool allowContributionAfterTargetIsMet
    );
    event CampaignDeadlineExtended(uint256 time);
    event DeadlineThresholdExtended(uint8 count);

    /// @dev `Approval Transfer`
    event CampaignUserDataTransferred(address oldAddress, address newAddress);

    /// @dev `Contribution Events`
    event ContributorApprovalToggled(address contributor, bool isApproved);
    event ContributionMade(
        uint256 indexed contributionId,
        uint256 amount,
        uint256 indexed rewardId,
        uint256 indexed rewardRecipientId,
        bool withReward
    );
    event ContributionWithdrawn(
        uint256 indexed contributionId,
        uint256 amount,
        address user
    );

    /// @dev `Request Event`
    event RequestComplete(uint256 indexed requestId);

    /// @dev `Review Events`
    event CampaignReviewed(address user, string hashedReview);
    event CampaignReported(address user, string hashedReport);

    /// @dev `Campaign State Events`
    event CampaignStateChange(CAMPAIGN_STATE state);
    event WithdrawalStateUpdated(bool withdrawalState);

    ICampaignFactory public campaignFactoryContract;
    ICampaignReward public campaignRewardContract;
    ICampaignRequest public campaignRequestContract;
    ICampaignVote public campaignVoteContract;

    /// @dev `Contribution`
    struct Contribution {
        uint256 amount;
        bool withdrawn;
    }
    Contribution[] contributions;
    mapping(address => uint256) public contributionId;

    /// @dev `Review`
    uint256 public reviewCount;
    mapping(address => bool) public reviewed;
    mapping(address => string) public reviewHash;

    address public root;
    address public acceptedToken;
    bool public allowContributionAfterTargetIsMet;
    bool public withdrawalsPaused;
    uint8 public percentBase;
    uint256 public percent;
    uint256 public totalCampaignContribution;
    uint256 public campaignBalance;
    uint256 public minimumContribution;
    uint256 public approversCount;
    uint256 public target;
    uint256 public deadline;
    uint256 public deadlineSetTimes;
    uint256 public reportCount;
    mapping(address => bool) public allowedToContribute;
    mapping(address => bool) public approvers;
    mapping(address => bool) public reported;
    mapping(address => string) public reportHash;

    mapping(address => uint256) public transferAttemptCount;
    mapping(address => uint256) public timeUntilNextTransferConfirmation;

    /// @dev Ensures caller is only factory
    modifier onlyFactory() {
        require(
            CampaignFactoryLib.canManageCampaigns(
                campaignFactoryContract,
                msg.sender
            ),
            "only factory"
        );
        _;
    }

    /// @dev Ensures a user is verified
    modifier userIsVerified(address _user) {
        bool verified;
        (, , verified) = CampaignFactoryLib.userInfo(
            campaignFactoryContract,
            _user
        );
        require(verified, "unverified");
        _;
    }

    /// @dev Ensures user account is not in transit process
    modifier userTransferNotInTransit() {
        require(
            !campaignFactoryContract.accountInTransit(msg.sender),
            "in transit"
        );
        _;
    }

    /**
     * @dev        Constructor
     * @param      _campaignFactory     Address of factory
     * @param      _campaignRewards     Address of campaign reward contract
     * @param      _campaignRequests    Address of campaign request contract
     * @param      _campaignVotes       Address of campaign vote contract
     * @param      _root                Address of campaign owner
     */
    function __Campaign_init(
        CampaignFactory _campaignFactory,
        CampaignReward _campaignRewards,
        CampaignRequest _campaignRequests,
        CampaignVote _campaignVotes,
        address _root
    ) public initializer {
        require(address(_root) != address(0));

        campaignFactoryContract = ICampaignFactory(address(_campaignFactory));
        campaignRewardContract = ICampaignReward(address(_campaignRewards));
        campaignRequestContract = ICampaignRequest(address(_campaignRequests));
        campaignVoteContract = ICampaignVote(address(_campaignVotes));

        root = _root;
        campaignState = CAMPAIGN_STATE.COLLECTION;
        percentBase = 100;
        percent = percentBase.mul(DecimalMath.UNIT);
        withdrawalsPaused = false;

        _setupRole(DEFAULT_ADMIN_ROLE, root);
        _setupRole(SET_CAMPAIGN_SETTINGS, root);
        _setupRole(EXTEND_DEADLINE, root);
        _setupRole(CONTRIBUTOR_APPROVAL, root);
        _setupRole(FINALIZE_REQUEST, root);
        _setupRole(REVIEW_MODE, root);
        _setupRole(MARK_CAMPAIGN_COMPLETE, root);

        _setRoleAdmin(SET_CAMPAIGN_SETTINGS, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(EXTEND_DEADLINE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONTRIBUTOR_APPROVAL, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(FINALIZE_REQUEST, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(REVIEW_MODE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MARK_CAMPAIGN_COMPLETE, DEFAULT_ADMIN_ROLE);

        emit CampaignOwnerSet(root);
    }

    /**
     * @dev        Checks if a provided address is a campaign admin
     * @param      _user     Address of the user
     */
    function isCampaignAdmin(address _user) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _user);
    }

    /**
     * @dev        Checks if a provided address has role
     * @param      _permission     Role being checked
     * @param      _account        Address of the user
     */
    function isAllowed(bytes32 _permission, address _account)
        external
        view
        returns (bool)
    {
        return hasRole(_permission, _account);
    }

    /**
     * @dev        Returns the campaigns funding goal type
     * @param      _goalType    Integer representing a goal type
     */
    function getCampaignGoalType(uint256 _goalType)
        external
        pure
        returns (GOALTYPE)
    {
        return GOALTYPE(_goalType);
    }

    /**
     * @dev        Returns a campaign state by a provided index
     * @param      _state     Integer representing a state in the campaign
     */
    function getCampaignState(uint256 _state)
        external
        pure
        returns (CAMPAIGN_STATE)
    {
        return CAMPAIGN_STATE(_state);
    }

    /**
     * @dev        Transfers campaign ownership from one user to another.
     * @param      _oldRoot    Address of the user campaign ownership is being transfered from
     * @param      _newRoot    Address of the user campaign ownership is being transfered to
     */
    function transferCampaignOwnership(address _oldRoot, address _newRoot)
        public
        onlyAdmin
        whenNotPaused
    {
        require(_oldRoot == root);

        root = _newRoot;
        _setupRole(DEFAULT_ADMIN_ROLE, _newRoot);
        renounceRole(DEFAULT_ADMIN_ROLE, _oldRoot);

        emit CampaignOwnershipTransferred(_newRoot);
    }

    /**
     * @dev        Transfers user data in the campaign to another verifed user
     * @param      _oldAddress    Address of the user transferring
     * @param      _newAddress    Address of the user being transferred to
     */
    function transferCampaignUserData(address _oldAddress, address _newAddress)
        external
        nonReentrant
        whenNotPaused
        userIsVerified(_newAddress)
    {
        // check if in transfer process from parent contract
        require(
            campaignFactoryContract.accountInTransit(_oldAddress),
            "not in transit"
        );
        require(
            campaignFactoryContract.isUserTrustee(_oldAddress, msg.sender),
            "not a trustee"
        );
        require(
            campaignState == CAMPAIGN_STATE.COLLECTION ||
                campaignState == CAMPAIGN_STATE.LIVE,
            "not live or in collection"
        );
        require(approvers[_oldAddress], "not an approver");
        require(
            transferAttemptCount[_oldAddress] <= 6,
            "transfer attempts exhausted"
        );
        require(
            timeUntilNextTransferConfirmation[_oldAddress] >= block.timestamp,
            "time until next confirmation not expired"
        );

        if (transferAttemptCount[_oldAddress] < 3) {
            transferAttemptCount[_oldAddress] = transferAttemptCount[
                _oldAddress
            ].add(1);
            timeUntilNextTransferConfirmation[_oldAddress] = block
                .timestamp
                .add(30 minutes);
            return;
        } else {
            // transfer balance
            contributions[contributionId[_newAddress]].amount = contributions[
                contributionId[_oldAddress]
            ].amount;
            contributions[contributionId[_oldAddress]].amount = 0;

            // transfer approver account
            approvers[_oldAddress] = false;
            approvers[_newAddress] = true;

            CampaignRewardLib._transferRewards(
                campaignRewardContract,
                _oldAddress,
                _newAddress
            );

            emit CampaignUserDataTransferred(_oldAddress, _newAddress);
        }
    }

    /**
     * @dev         Modifies campaign details
     * @param      _target                              Contribution target of the campaign
     * @param      _minimumContribution                 The minimum amout required to be an approver
     * @param      _duration                            How long until the campaign stops receiving contributions
     * @param      _goalType                            If flexible the campaign owner is able to create requests if targe isn't met, fixed opposite
     * @param      _token                               Address of token to be used for transactions by default
     * @param      _allowContributionAfterTargetIsMet   Indicates if the campaign can receive contributions after the target is met
     */
    function setCampaignSettings(
        uint256 _target,
        uint256 _minimumContribution,
        uint256 _duration,
        uint256 _goalType,
        address _token,
        bool _allowContributionAfterTargetIsMet
    ) external userTransferNotInTransit hasPermission(SET_CAMPAIGN_SETTINGS) {
        require(approversCount < 1, "approvers found");
        require(
            _minimumContribution >=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minimumContributionAllowed"
                ) &&
                _minimumContribution <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumContributionAllowed"
                ),
            "contribution deficit"
        );
        require(
            _target >=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minimumCampaignTarget"
                ) &&
                _target <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumCampaignTarget"
                ),
            "target deficit"
        );

        bool approved;
        (, , approved) = campaignFactoryContract.tokens(_token);
        require(approved, "invalid token");

        bool campaignIsApproved;
        (, campaignIsApproved) = CampaignFactoryLib.campaignInfo(
            campaignFactoryContract,
            this
        );
        require(!campaignIsApproved, "already approved");

        target = _target;
        minimumContribution = _minimumContribution;
        deadline = block.timestamp.add(_duration);
        acceptedToken = _token;
        allowContributionAfterTargetIsMet = _allowContributionAfterTargetIsMet;
        goalType = GOALTYPE(_goalType);

        emit CampaignSettingsUpdated(
            _target,
            _minimumContribution,
            _duration,
            _goalType,
            _token,
            _allowContributionAfterTargetIsMet
        );
    }

    /**
     * @dev        Extends campaign contribution deadline
     * @param      _time    How long until the campaign stops receiving contributions
     */
    function extendDeadline(uint256 _time)
        external
        hasPermission(EXTEND_DEADLINE)
        userTransferNotInTransit
        nonReentrant
        whenNotPaused
    {
        require(block.timestamp > deadline);
        require(
            deadlineSetTimes <
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "deadlineStrikesAllowed"
                ),
            "exhausted strikes"
        );
        require(
            _time <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maxDeadlineExtension"
                ) &&
                _time >=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minDeadlineExtension"
                ),
            "time deficit"
        ); // ensure time exceeds 7 days and less than a day

        deadline = block.timestamp.add(_time);

        // limit ability to increase deadlines
        deadlineSetTimes = deadlineSetTimes.add(1);

        emit CampaignDeadlineExtended(_time);
    }

    /**
     * @dev        Sets the number of times the campaign owner can extend deadlines.
     * @param      _count   Number of times a campaign owner can extend the deadline
     */
    function setDeadlineSetTimes(uint8 _count)
        external
        hasPermission(EXTEND_DEADLINE)
        userTransferNotInTransit
        whenNotPaused
    {
        deadlineSetTimes = _count;

        emit DeadlineThresholdExtended(_count);
    }

    /**
     * @dev        Approves or unapproves a potential contributor
     * @param      _contributor     Address of the potential contributor
     */
    function toggleContributorApproval(address _contributor)
        external
        hasPermission(CONTRIBUTOR_APPROVAL)
    {
        require(_contributor != address(0));

        if (allowedToContribute[_contributor]) {
            // check there are no finalized requests
            require(
                campaignRequestContract.finalizedRequestCount() < 1,
                "request finalized"
            );
            allowedToContribute[_contributor] = false;
        } else {
            allowedToContribute[_contributor] = true;
        }

        emit ContributorApprovalToggled(
            _contributor,
            allowedToContribute[_contributor]
        );
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
        userIsVerified(msg.sender)
        userTransferNotInTransit
        whenNotPaused
        nonReentrant
    {
        // check if campaign is private, if it is check if user is approved contributor
        bool privateCampaign;

        (, privateCampaign) = CampaignFactoryLib.campaignInfo(
            campaignFactoryContract,
            this
        );

        if (privateCampaign) {
            require(allowedToContribute[msg.sender], "not approved");
        }

        // campaign owner cannot contribute to own campaign
        // token must be accepted
        // contrubution amount must be less than or equal to allowed value from factory
        require(block.timestamp <= deadline, "deadline expired");
        require(msg.sender != root, "root owner");
        require(_token == acceptedToken, "invalid token");
        require(msg.value >= minimumContribution, "value low");
        require(
            msg.value <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumContributionAllowed"
                ),
            "value high"
        );

        uint256 _rewardRecipientId;

        if (!allowContributionAfterTargetIsMet) {
            // check user contribution added to current total contribution doesn't exceed target
            require(
                totalCampaignContribution.add(msg.value) <= target,
                "exceeds target"
            );
        }

        if (_withReward) {
            (_rewardRecipientId) = CampaignRewardLib._assignReward(
                campaignRewardContract,
                _rewardId,
                msg.value,
                msg.sender
            );
        }

        if (!approvers[msg.sender]) {
            approversCount = approversCount.add(1);
            approvers[msg.sender] = true;
            contributions.push(Contribution(msg.value, false));
            contributionId[msg.sender] = contributions.length.sub(1);
        }

        totalCampaignContribution = totalCampaignContribution.add(msg.value);
        campaignBalance = campaignBalance.add(msg.value);
        contributions[contributionId[msg.sender]].amount = contributions[
            contributionId[msg.sender]
        ].amount.add(msg.value);

        // keep track of when target is met
        if (totalCampaignContribution >= target) {
            campaignState = CAMPAIGN_STATE.LIVE;
        }

        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(acceptedToken),
            msg.sender,
            address(this),
            msg.value
        );

        emit ContributionMade(
            contributionId[msg.sender],
            msg.value,
            _rewardId,
            _rewardRecipientId,
            _withReward
        );
    }

    /**
     * @dev        Allows withdrawal of contribution by a user, works if campaign target isn't met
     * @param      _wallet    Address where amount is delivered
     */
    function withdrawContribution(address payable _wallet)
        external
        userTransferNotInTransit
        nonReentrant
    {
        require(!withdrawalsPaused);

        // if the campaign state is neither unsuccessful and in review and there are reviews
        // allow withdrawls
        require(address(_wallet) != address(0));
        require(
            !contributions[contributionId[msg.sender]].withdrawn,
            "withdrawn"
        );
        require(approvers[msg.sender], "non approver");

        if (
            campaignState != CAMPAIGN_STATE.UNSUCCESSFUL &&
            campaignState != CAMPAIGN_STATE.REVIEW &&
            reviewCount < 1
        ) {
            // pledge collection ongoing and no request was successful
            require(
                campaignState == CAMPAIGN_STATE.COLLECTION ||
                    campaignState == CAMPAIGN_STATE.LIVE,
                "not in collection or live stage"
            );
            require(
                campaignRequestContract.finalizedRequestCount() < 1,
                "request(s) finalized"
            );
        }
        uint256 maxBalance = contributions[contributionId[msg.sender]]
            .amount
            .sub(userContributionLoss(msg.sender));

        // no longer eligible for any reward if campaign is not unsuccessful or in review
        // for record keeping purposes
        if (
            campaignState != CAMPAIGN_STATE.UNSUCCESSFUL &&
            campaignState != CAMPAIGN_STATE.REVIEW
        ) {
            CampaignRewardLib._renounceRewards(
                campaignRewardContract,
                msg.sender
            );

            // decrement total contributions to campaign
            campaignBalance = campaignBalance.sub(maxBalance);
            totalCampaignContribution = totalCampaignContribution.sub(
                maxBalance
            );

            // mark user as a non contributor
            approvers[msg.sender] = false;

            // reduce approvers count
            approversCount = approversCount.sub(1);

            contributions[contributionId[msg.sender]].amount = 0;
        } else {
            contributions[contributionId[msg.sender]].amount = contributions[
                contributionId[msg.sender]
            ].amount.sub(maxBalance);
        }
        contributions[contributionId[msg.sender]].withdrawn = true;

        // transfer to msg.sender
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(acceptedToken),
            _wallet,
            maxBalance
        );

        emit ContributionWithdrawn(
            contributionId[msg.sender],
            maxBalance,
            msg.sender
        );
    }

    /**
     * @dev        Used to measure user funds left after request finalization
     * @param      _user    Address of user check is carried out on
     */
    function userContributionLoss(address _user) public view returns (uint256) {
        require(!contributions[contributionId[_user]].withdrawn, "withdrawn");

        // calculate % loss between totalCampaginContribution and campaginBalance
        DecimalMath.UFixed memory percentTakenSoFar = DecimalMath.muld(
            DecimalMath.divd(
                totalCampaignContribution.sub(campaignBalance),
                totalCampaignContribution
            ),
            percent
        );
        // calculate % loss of userBalance and subtract loss
        uint256 userLoss = DecimalMath.muldrup(
            contributions[contributionId[_user]].amount,
            DecimalMath.divd(percentTakenSoFar, percent)
        );

        return userLoss;
    }

    /**
     * @dev        Withdrawal method called only when a request receives the right amount of votes
     * @param      _requestId      ID of request being withdrawn
     */
    function finalizeRequest(uint256 _requestId)
        external
        hasPermission(FINALIZE_REQUEST)
        userTransferNotInTransit
        whenNotPaused
        nonReentrant
    {
        uint256 requestValue;

        (, requestValue, , , , , , , ) = campaignRequestContract.requests(
            _requestId
        );

        campaignBalance = campaignBalance.sub(requestValue);
        campaignRequestContract.signRequestFinalization(_requestId);

        emit RequestComplete(_requestId);
    }

    /// @dev Pauses the campaign and switches `campaignState` to `REVIEW` indicating it's ready to be reviewd by it's approvers after the campaign is over
    function markReviewMode()
        external
        hasPermission(REVIEW_MODE)
        userTransferNotInTransit
        whenNotPaused
    {
        // ensure finalized requests is more than or equal to 1
        // ensure no pending request
        // ensure campaign state is running
        bool requestComplete;

        (, , , , , , , requestComplete, ) = campaignRequestContract.requests(
            campaignRequestContract.currentRunningRequest()
        );

        require(
            campaignState == CAMPAIGN_STATE.LIVE ||
                campaignState == CAMPAIGN_STATE.COLLECTION,
            "not ongoing"
        );
        require(
            campaignRequestContract.finalizedRequestCount() >= 1,
            "no finalized requests"
        );
        require(requestComplete, "request ongoing");

        campaignState = CAMPAIGN_STATE.REVIEW;
        _pause();

        emit CampaignStateChange(CAMPAIGN_STATE.REVIEW);
    }

    /**
     * @dev        User acknowledgement of review state enabled by the campaign owner
     * @param      _hashedReview    CID reference of the review on IPFS
     */
    function reviewCampaignPerformance(string memory _hashedReview)
        external
        userTransferNotInTransit
        userIsVerified(msg.sender)
        whenPaused
    {
        require(campaignState == CAMPAIGN_STATE.REVIEW, "not in review");
        require(!reviewed[msg.sender], "reviewed");
        require(approvers[msg.sender], "non approver");

        reviewed[msg.sender] = true;
        reviewHash[msg.sender] = _hashedReview;

        reviewCount = reviewCount.add(1);

        emit CampaignReviewed(msg.sender, _hashedReview);
    }

    /// @dev Called by campaign manager to mark the campaign as complete right after it secured enough reviews from users
    function markCampaignComplete()
        external
        hasPermission(MARK_CAMPAIGN_COMPLETE)
        userTransferNotInTransit
        whenPaused
    {
        // check if reviewers count > 80% of approvers set campaign state to complete
        DecimalMath.UFixed memory percentOfApprovals = DecimalMath.muld(
            DecimalMath.divd(
                DecimalMath.toUFixed(reviewCount),
                DecimalMath.toUFixed(approversCount)
            ),
            percent
        );
        require(campaignState == CAMPAIGN_STATE.REVIEW, "not in review");
        require(
            percentOfApprovals.value >=
                CampaignFactoryLib
                    .getCampaignFactoryConfig(
                        campaignFactoryContract,
                        "reviewThresholdMark"
                    )
                    .mul(DecimalMath.UNIT),
            "review deficit"
        );
        campaignState = CAMPAIGN_STATE.COMPLETE;

        emit CampaignStateChange(CAMPAIGN_STATE.COMPLETE);
    }

    /**
     * @dev        Called by an approver to report a campaign. Campaign must be in collection or live state
     * @param      _hashedReport    CID reference of the report on IPFS
     */
    function reportCampaign(string memory _hashedReport)
        external
        userTransferNotInTransit
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(campaignRequestContract.requestCount() >= 1, "no requests");
        require(approvers[msg.sender], "non approver");
        require(
            campaignState == CAMPAIGN_STATE.COLLECTION ||
                campaignState == CAMPAIGN_STATE.LIVE,
            "not in collection or live state"
        );
        require(!reported[msg.sender], "reported");

        reported[msg.sender] = true;
        reportHash[msg.sender] = _hashedReport;
        reportCount = reportCount.add(1);

        DecimalMath.UFixed memory percentOfReports = DecimalMath.muld(
            DecimalMath.divd(
                DecimalMath.toUFixed(reportCount),
                DecimalMath.toUFixed(approversCount)
            ),
            percent
        );

        if (
            percentOfReports.value >=
            CampaignFactoryLib
                .getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "reportThresholdMark"
                )
                .mul(DecimalMath.UNIT)
        ) {
            campaignState = CAMPAIGN_STATE.UNSUCCESSFUL;

            emit CampaignStateChange(campaignState);

            _pause();
        }

        emit CampaignReported(msg.sender, _hashedReport);
    }

    /**
     * @dev        Sets the campaign state
     * @param      _state      Indicates pause or unpause state
     */
    function setCampaignState(uint256 _state) external onlyFactory {
        campaignState = CAMPAIGN_STATE(_state);

        emit CampaignStateChange(campaignState);
    }

    /**
     * @dev        Pauses or Unpauses withdrawals depending on state passed in argument
     * @param      _state      Indicates pause or unpause state
     */
    function toggleWithdrawalState(bool _state) external onlyFactory {
        withdrawalsPaused = _state;

        emit WithdrawalStateUpdated(_state);
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
