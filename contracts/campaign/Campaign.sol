// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../CampaignFactory.sol";
import "./CampaignReward.sol";
import "../utils/AccessControl.sol";

import "../interfaces/ICampaignFactory.sol";
import "../interfaces/IReward.sol";

import "../libraries/contracts/CampaignFactoryLib.sol";
import "../libraries/contracts/RewardLib.sol";

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

    bytes32 public constant MANAGER = keccak256("MANAGER");

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
    event CampaignOwnerSet(
        address user
    );

    /// @dev `Campaign Config Events`
    event CampaignOwnershipTransferred(
        address newOwner
    );
    event CampaignSettingsUpdated(
        uint256 target,
        uint256 minimumContribution,
        uint256 duration,
        uint256 goalType,
        address token,
        bool allowContributionAfterTargetIsMet
    );
    event CampaignDeadlineExtended(
        uint256 time
    );

    /// @dev `Approval Transfer`
    event CampaignUserDataTransferred(
        address oldAddress,
        address newAddress
    );

    /// @dev `Contribution Events`
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

    // /// @dev `Request Events`
    // event RequestAdded(
    //     uint256 indexed requestId,
    //     uint256 duration,
    //     uint256 value,
    //     address recipient
    // );
    // event RequestVoided(
    //     uint256 indexed requestId
    // );
    // event RequestComplete(
    //     uint256 indexed requestId
    // );

    // /// @dev `Vote Events`
    // event Voted(
    //     uint256 indexed voteId,
    //     uint256 indexed requestId,
    //     uint8 support
    // );
    // event VoteCancelled(
    //     uint256 indexed voteId,
    //     uint256 indexed requestId,
    //     uint8 support
    // );

    /// @dev `Review Events`
    event CampaignReviewed(address user);
    event CampaignReported(address user);

    /// @dev `Campaign State Events`
    event CampaignStateChange(
        CAMPAIGN_STATE state
    );

    ICampaignFactory public campaignFactoryContract;
    IReward private campaignRewardContract;

    /// @dev `Contribution`
    struct Contribution {
        uint256 amount;
        bool withdrawn;
    }
    Contribution[] contributions;
    mapping(address => uint256) public contributionId;

    // /// @dev `Vote`
    // struct Vote {
    //     uint8 support;
    //     uint256 requestId;
    //     bool voted;
    //     address approver;
    // }
    // Vote[] votes;
    // mapping(address => mapping(uint256 => uint256)) voteId; // { user -> request -> vote }

    // /// @dev `Request`
    // struct Request {
    //     address payable recipient;
    //     bool complete;
    //     uint256 value;
    //     uint256 approvalCount;
    //     uint256 againstCount;
    //     uint256 abstainedCount;
    //     uint256 duration;
    //     bool void;
    // }
    // uint256 public requestCount;
    // Request[] public requests;

    /// @dev `Review`
    uint256 public reviewCount;
    mapping(address => bool) public reviewed;

    address public root;
    address public acceptedToken;
    bool public allowContributionAfterTargetIsMet;
    bool public withdrawalsPaused;
    uint8 private percentBase;
    uint256 private percent;
    uint256 public campaignID;
    uint256 public totalCampaignContribution;
    uint256 public campaignBalance;
    uint256 public minimumContribution;
    uint256 public approversCount;
    uint256 public target;
    uint256 public deadline;
    uint256 public deadlineSetTimes;
    // uint256 public finalizedRequestCount;
    // uint256 public currentRunningRequest;
    uint256 public reportCount;
    mapping(address => bool) public approvers;
    mapping(address => bool) public reported;

    /// @dev Ensures caller is only factory, works only if campaign is approved
    modifier onlyFactory() {
        bool campaignIsApproved;
        (, , , campaignIsApproved,) = CampaignFactoryLib
            .campaignInfo(campaignFactoryContract, campaignID);
        
        if (campaignIsApproved) {
            require(
                CampaignFactoryLib.canManageCampaigns(
                    campaignFactoryContract,
                    msg.sender
                ),
                "only factory"
            );
        }
        _;
    }

    /// @dev Ensures caller is factory if campaign is approved or campaign owner
    modifier adminOrFactory() {
        bool campaignIsApproved;
        (, , , campaignIsApproved,) = CampaignFactoryLib
            .campaignInfo(campaignFactoryContract, campaignID);

        if (campaignIsApproved) {
            require(
                CampaignFactoryLib.canManageCampaigns(
                    campaignFactoryContract,
                    msg.sender
                ), "only admin"
            );
        }

        if (!campaignIsApproved) {
            require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin");
        }
        _;
    }

    /// @dev Ensures a user is verified
    modifier userIsVerified(address _user) {
        bool verified;
        (, verified) = CampaignFactoryLib.userInfo(
            campaignFactoryContract,
            _user
        );
        require(verified, "unverified");
        _;
    }

    /**
     * @dev        Constructor
     * @param      _campaignFactory     Address of factory
     * @param      _root                Address of campaign owner
     */
    function __Campaign_init(
        CampaignFactory _campaignFactory,
        CampaignReward _camaignRewards, 
        address _root,
        uint256 _campaignId
    )
        public
        initializer
    {
        require(address(_root) != address(0));

        campaignFactoryContract = ICampaignFactory(
            address(_campaignFactory)
        );
        campaignRewardContract = IReward(address(_camaignRewards));
        
        root = _root;
        campaignState = CAMPAIGN_STATE.COLLECTION;
        campaignID = _campaignId;
        percentBase = 100;
        percent = percentBase.mul(DecimalMath.UNIT);
        withdrawalsPaused = false;

        _setupRole(DEFAULT_ADMIN_ROLE, root);
        _setupRole(MANAGER, root);

        _setRoleAdmin(MANAGER, DEFAULT_ADMIN_ROLE);

        emit CampaignOwnerSet(root);
    }

    /**
     * @dev        Transfers campaign ownership from one user to another.
     * @param      _newRoot    Address of the user campaign ownership is being transfered to
     */
    function transferCampaignOwnership(address _newRoot)
        external
        onlyAdmin
        whenNotPaused
    {
        root = _newRoot;
        _setupRole(DEFAULT_ADMIN_ROLE, _newRoot);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit CampaignOwnershipTransferred(_newRoot);
    }

    /**
     * @dev        Transfers user data in the campaign to another verifed user
     * @param      _oldAddress    Address of the user transferring
     * @param      _newAddress    Address of the user being transferred to
     */
    function transferCampaignUserData(address _oldAddress, address _newAddress)
        external
        onlyFactory
        nonReentrant
        whenNotPaused
        userIsVerified(_newAddress)
    {
        require(
            campaignState == CAMPAIGN_STATE.COLLECTION ||
                campaignState == CAMPAIGN_STATE.LIVE
        );
        require(approvers[_oldAddress]);

        // transfer balance
        contributions[contributionId[_newAddress]].amount = contributions[contributionId[_oldAddress]].amount;
        contributions[contributionId[_oldAddress]].amount = 0;

        // transfer approver account
        approvers[_oldAddress] = false;
        approvers[_newAddress] = true;

        RewardLib._transferRewards(
            campaignRewardContract,
            _oldAddress,
            _newAddress
        );

        emit CampaignUserDataTransferred(
            _oldAddress,
            _newAddress
        );
    }

    /**
     * @dev         Modifies campaign details while it's not approved
     * @param      _target                              Contribution target of the campaign
     * @param      _minimumContribution                 The minimum amout required to be an approver
     * @param      _duration                            How long until the campaign stops receiving contributions
     * @param      _goalType                            If flexible the campaign owner is able to create requests if targe isn't met, fixed opposite
     * @param      _token                               Address of token to be used for transactions by default
     * @param      _allowContributionAfterTargetIsMet   Indicates if the campaign can receive contributions after duration expires
     */
    function setCampaignSettings(
        uint256 _target,
        uint256 _minimumContribution,
        uint256 _duration,
        uint256 _goalType,
        address _token,
        bool _allowContributionAfterTargetIsMet
    ) external onlyAdmin {
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
            campaignFactoryContract.tokensApproved(_token),
            "invalid token"
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
        onlyAdmin
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
     * @dev        Sets the number of times the campaign owner can extended deadlines.
     * @param      _count   Number of times a campaign owner can extend the deadline
     */
    function setDeadlineSetTimes(uint8 _count)
        external
        adminOrFactory
        whenNotPaused
    {
        deadlineSetTimes = _count;
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
        whenNotPaused
        nonReentrant
    {
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
                msg.value <= target &&
                    totalCampaignContribution.add(msg.value) <= target,
                "exceeds target"
            );
        }

        if (_withReward) {
             ( _rewardRecipientId ) = RewardLib._assignReward(
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
        contributions[contributionId[msg.sender]].amount = contributions[contributionId[msg.sender]].amount.add(msg.value);

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
    function withdrawOwnContribution(address payable _wallet)
        external
        nonReentrant
    {
        require(!withdrawalsPaused);
        _withdrawContribution(msg.sender, _wallet);
    }

    /**
     * @dev        Allows withdrawal of balance by factory on behalf of a user. 
                   Cases where users wallet is compromised
     * @param      _user      User whose funds are being requested
     * @param      _wallet    Address where amount is delivered
     */
    function withdrawContributionForUser(address _user, address payable _wallet)
        external
        onlyFactory
        nonReentrant
    {
        require(!withdrawalsPaused);
        _withdrawContribution(_user, _wallet);
    }

    /**
     * @dev        Used to measure user funds left after request finalizations
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
     * @dev        Private `_withdrawContribution` implemented by `withdrawOwnContribution` and `withdrawContributionForUser`
     * @param      _user      User whose funds are being requested
     * @param      _wallet    Address where amount is delivered
     */
    function _withdrawContribution(address _user, address _wallet) private {
        // if the campaign state is neither unsuccessful and in review and there are reviews
        // allow withdrawls
        require(address(_wallet) != address(0));
        require(!contributions[contributionId[_user]].withdrawn, "withdrawn");
        require(approvers[_user], "non approver");

        if (
            campaignState != CAMPAIGN_STATE.UNSUCCESSFUL &&
            campaignState != CAMPAIGN_STATE.REVIEW &&
            reviewCount < 1
        ) {
            // pledge collection ongoing and no request was successful
            require(
                campaignState == CAMPAIGN_STATE.COLLECTION,
                "not in collection stage"
            );
            require(finalizedRequestCount < 1, "request(s) finalized");
        }
        uint256 maxBalance = contributions[contributionId[_user]].amount.sub(
            userContributionLoss(_user)
        );

        // no longer eligible for any reward if campaign is not unsuccessful or in review
        // for record keeping purposes
        if (
            campaignState != CAMPAIGN_STATE.UNSUCCESSFUL &&
            campaignState != CAMPAIGN_STATE.REVIEW
        ) {
            RewardLib._renounceRewards(campaignRewardContract, _user);

            // decrement total contributions to campaign
            campaignBalance = campaignBalance.sub(maxBalance);
            totalCampaignContribution = totalCampaignContribution.sub(
                maxBalance
            );

            // mark user as a non contributor
            approvers[_user] = false;

            // reduce approvers count
            approversCount = approversCount.sub(1);

            contributions[contributionId[_user]].amount = 0;
        } else {
            contributions[contributionId[_user]].amount = contributions[contributionId[_user]].amount.sub(
                maxBalance
            );
        }
        contributions[contributionId[_user]].withdrawn = true;

        // transfer to _user
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(acceptedToken),
            _wallet,
            maxBalance
        );

        emit ContributionWithdrawn(contributionId[_user], maxBalance, _user);
    }

    // /**
    //  * @dev        Creates a formal request to withdraw funds from user contributions called by the campagn manager or factory
    //                Restricted unless target is met and deadline is expired
    //  * @param      _recipient   Address where requested funds are deposited
    //  * @param      _value       Amount being requested by the campaign manager
    //  * @param      _duration    Duration until users aren't able to vote on the request
    //  */
    // function createRequest(
    //     address payable _recipient,
    //     uint256 _value,
    //     uint256 _duration
    // )
    //     external
    //     onlyAdmin
    //     whenNotPaused
    // {
    //     require(address(_recipient) != address(0));

    //     if (totalCampaignContribution < target)
    //         require(block.timestamp >= deadline, "deadline not expired");
        
    //     if (goalType == GOALTYPE.FIXED) {
    //         require(
    //             totalCampaignContribution >= target &&
    //                 campaignState == CAMPAIGN_STATE.LIVE,
    //             "target unmet"
    //         );
    //     }
    //     require(
    //         _value >=
    //             CampaignFactoryLib.getCampaignFactoryConfig(
    //                 campaignFactoryContract,
    //                 "minimumRequestAmountAllowed"
    //             ) && _value <=
    //             CampaignFactoryLib.getCampaignFactoryConfig(
    //                 campaignFactoryContract,
    //                 "maximumRequestAmountAllowed"
    //             ),
    //         "amount deficit"
    //     );
    //     require(
    //         _value <= campaignBalance,
    //         "amount over balance"
    //     );
    //     require(
    //         _duration >=
    //             CampaignFactoryLib.getCampaignFactoryConfig(
    //                 campaignFactoryContract,
    //                 "minRequestDuration"
    //             ) && _duration <=
    //             CampaignFactoryLib.getCampaignFactoryConfig(
    //                 campaignFactoryContract,
    //                 "maxRequestDuration"
    //             ),
    //         "duration deficit"
    //     );

    //     // before creating a new request last request should be complete
    //     // applies if there's a request before
    //     if (requestCount >= 1)
    //         require(
    //             requests[currentRunningRequest].complete,
    //             "request ongoing"
    //         );

    //     requests.push(
    //         Request(
    //             _recipient,
    //             false,
    //             _value,
    //             0,
    //             0,
    //             0,
    //             block.timestamp.add(_duration),
    //             false
    //         )
    //     );
    //     requestCount = requestCount.add(1);
    //     currentRunningRequest = requests.length.sub(1);

    //     emit RequestAdded(
    //         requests.length.sub(1),
    //         _duration,
    //         _value,
    //         _recipient
    //     );
    // }

    // /**
    //  * @dev        Renders a request void and useless
    //  * @param      _requestId   ID of request being voided
    //  */
    // function voidRequest(uint256 _requestId)
    //     external
    //     onlyAdmin
    //     whenNotPaused
    // {
    //     // request must not be void
    //     // request must have no votes
    //     // request should not have been finalized
    //     require(!requests[_requestId].void, "voided");
    //     require(requests[_requestId].approvalCount < 1, "has approvals");
    //     // require(!requests[_requestId].complete, "already finalized");

    //     requests[_requestId].void = true;

    //     emit RequestVoided(_requestId);
    // }

    // /**
    //  * @dev        Approvers only method which approves spending request issued by the campaign manager or factory
    //  * @param      _requestId   ID of request being voted on
    //  * @param      _support     An integer of 0 for against, 1 for in-favor, and 2 for abstain
    //  */
    // function voteOnRequest(uint256 _requestId, uint8 _support)
    //     external
    //     userIsVerified(msg.sender)
    //     whenNotPaused
    // {
    //     require(approvers[msg.sender], "non approver");
    //     require(!votes[voteId[msg.sender][_requestId]].voted, "voted");
    //     require(
    //         block.timestamp <= requests[_requestId].duration,
    //         "request expired"
    //     );

    //     require(!requests[_requestId].void, "voided");

    //     if (_support == 0) {
    //         requests[_requestId].againstCount = requests[_requestId]
    //             .againstCount
    //             .add(1);
    //     } else if (_support == 1) {
    //         requests[_requestId].approvalCount = requests[_requestId]
    //             .approvalCount
    //             .add(1);
    //     } else {
    //         requests[_requestId].abstainedCount = requests[_requestId]
    //             .abstainedCount
    //             .add(1);
    //     }
    
    //     votes.push(Vote(_support, _requestId, true, msg.sender));
    //     voteId[msg.sender][_requestId] = votes.length.sub(1);

    //     emit Voted(votes.length.sub(1), _requestId, _support);
    // }

    // /**
    //  * @dev        Approvers only method which cancels initial vote on a request
    //  * @param      _requestId   ID of request being voted on
    //  */
    // function cancelVote(uint256 _requestId)
    //     external
    //     userIsVerified(msg.sender)
    //     whenNotPaused
    // {
    //     require(approvers[msg.sender], "non approver");
    //     require(
    //         block.timestamp <= requests[_requestId].duration,
    //         "request expired"
    //     );
    //     require(votes[voteId[msg.sender][_requestId]].voted, "vote first");

    //     votes[voteId[msg.sender][_requestId]].voted = false;

    //     if (votes[voteId[msg.sender][_requestId]].support == 0) {
    //         requests[_requestId].againstCount = requests[_requestId]
    //             .againstCount
    //             .sub(1);
    //     } else if (votes[voteId[msg.sender][_requestId]].support == 1) {
    //         requests[_requestId].approvalCount = requests[_requestId]
    //             .approvalCount
    //             .sub(1);
    //     } else {
    //         requests[_requestId].abstainedCount = requests[_requestId]
    //             .abstainedCount
    //             .sub(1);
    //     }

    //     emit VoteCancelled(
    //         voteId[msg.sender][_requestId],
    //         _requestId,
    //         votes[voteId[msg.sender][_requestId]].support
    //     );
    // }

    // /**
    //  * @dev        Withdrawal method called only when a request receives the right amount votes
    //  * @param      _requestId      ID of request being withdrawn
    //  */
    // function finalizeRequest(uint256 _requestId)
    //     external
    //     onlyAdmin
    //     whenNotPaused
    //     nonReentrant
    // {
    //     Request storage request = requests[_requestId];
    //     // more than 50% of approvers to finalize
    //     DecimalMath.UFixed memory percentOfRequestApprovals = DecimalMath.muld(
    //         DecimalMath.divd(
    //             DecimalMath.toUFixed(request.approvalCount),
    //             DecimalMath.toUFixed(approversCount)
    //         ),
    //         percent
    //     );
    //     require(
    //         percentOfRequestApprovals.value >=
    //             CampaignFactoryLib.getCampaignFactoryConfig(
    //                 campaignFactoryContract,
    //                 "requestFinalizationThreshold"
    //             ).mul(DecimalMath.UNIT),
    //         "approval deficit"
    //     );
    //     require(!request.complete, "finalized");

    //     DecimalMath.UFixed memory factoryFee = DecimalMath.muld(
    //         DecimalMath.divd(
    //             CampaignFactoryLib.factoryPercentFee(
    //                 campaignFactoryContract,
    //                 campaignID
    //             ),
    //             percent
    //         ),
    //         request.value
    //     );

    //     uint256[2] memory payouts = [
    //         request.value.sub(factoryFee.value),
    //         factoryFee.value
    //     ];
    //     address payable[2] memory addresses = [
    //         request.recipient,
    //         campaignFactoryContract.factoryWallet()
    //     ];

    //     request.complete = true;
    //     finalizedRequestCount = finalizedRequestCount.add(1);
    //     campaignBalance = campaignBalance.sub(request.value);

    //     CampaignFactoryLib.sendCommissionFee(
    //         campaignFactoryContract,
    //         address(this),
    //         factoryFee.value
    //     );
        
    //     for (uint256 i = 0; i < addresses.length; i++) {
    //         SafeERC20Upgradeable.safeTransfer(
    //             IERC20Upgradeable(acceptedToken),
    //             addresses[i],
    //             payouts[i]
    //         );
    //     }

    //     emit RequestComplete(_requestId);
    // }

    /// @dev Pauses the campaign and switches `campaignState` to `REVIEW` indicating it's ready to be reviewd by it's approvers after the campaign is over
    function reviewMode()
        external
        onlyAdmin
        whenNotPaused
    {
        // ensure finalized requests is more than 1
        // ensure no pending request
        // ensure campaign state is running
        require(
            campaignState == CAMPAIGN_STATE.LIVE ||
                campaignState == CAMPAIGN_STATE.COLLECTION,
            "not ongoing"
        );
        require(finalizedRequestCount >= 1, "no finalized requests");
        require(requests[currentRunningRequest].complete, "request ongoing");

        campaignState = CAMPAIGN_STATE.REVIEW;
        _pause();

        emit CampaignStateChange(CAMPAIGN_STATE.REVIEW);
    }

    /// @dev User acknowledgement of review state enabled by the campaign owner
    function reviewCampaignPerformance()
        external
        userIsVerified(msg.sender)
        whenPaused
    {
        require(
            campaignState == CAMPAIGN_STATE.REVIEW,
            "not in review"
        );
        require(!reviewed[msg.sender], "reviewed");
        require(approvers[msg.sender], "non approver");

        reviewed[msg.sender] = true;

        reviewCount = reviewCount.add(1);

        emit CampaignReviewed(msg.sender);
    }

    /// @dev Called by campaign manager to mark the campaign as complete right after it secured enough reviews from users
    function markCampaignComplete()
        external
        onlyAdmin
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
        require(
            campaignState == CAMPAIGN_STATE.REVIEW,
            "not in review"
        );
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

        emit CampaignStateChange(
            CAMPAIGN_STATE.COMPLETE
        );
    }
    
    /// @dev Called by an approver to report a campaign. Campaign must be in collection or live state
    function reportCampaign()
        external
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(requestCount >= 1, "no requests");
        require(approvers[msg.sender], "non approver");
        require(
            campaignState == CAMPAIGN_STATE.COLLECTION ||
                campaignState == CAMPAIGN_STATE.LIVE,
            "not in collection or live state"
        );
        require(!reported[msg.sender], "reported");

        reported[msg.sender] = true;
        reportCount = reportCount.add(1);

        DecimalMath.UFixed memory percentOfReports = DecimalMath.muld(
            DecimalMath.divd(
                DecimalMath.toUFixed(reportCount),
                DecimalMath.toUFixed(approversCount)
            ),
            percent
        );
        
        if (percentOfReports.value 
            >= CampaignFactoryLib.getCampaignFactoryConfig(campaignFactoryContract, "reportThresholdMark").mul(DecimalMath.UNIT)
        ) {
            _setCampaignState(4);
            _pause();
        }

        emit CampaignReported(msg.sender);
    }

    /**
     * @dev        Changes campaign state
     * @param      _state      state of campaign
     */
    function _setCampaignState(uint256 _state) private {
        campaignState = CAMPAIGN_STATE(_state);

        emit CampaignStateChange(CAMPAIGN_STATE(_state));
    }

    /**
     * @dev        Pauses or Unpauses withdrawals depending on state passed in argument
     * @param      _state      Indicates pause or unpause state
     */
    function toggleWithdrawalState(bool _state) external onlyFactory {
        withdrawalsPaused = _state;
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