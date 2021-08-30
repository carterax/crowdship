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
import "./interfaces/FactoryInterface.sol";
import "./libraries/contracts/CampaignFactoryLib.sol";
import "./libraries/math/DecimalMath.sol";

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
        GENESIS,
        COLLECTION,
        LIVE,
        REVIEW,
        COMPLETE,
        UNSUCCESSFUL
    }
    CAMPAIGN_STATE public campaignState;

    /// @dev `Campaign`
    event CampaignOwnerSet(
        uint256 indexed campaignId,
        address user,
        address sender
    );
    event CampaignOwnershipTransferred(
        uint256 indexed campaignId,
        address newUser,
        address sender
    );
    event CampaignSettingsUpdated(
        uint256 indexed campaignId,
        uint256 minimumContribution,
        uint256 deadline,
        uint256 goalType,
        address token,
        address sender
    );
    event CampaignDeadlineExtended(
        uint256 indexed campaignId,
        uint256 time,
        address sender
    );
    // event CampaignReported(uint256 indexed campaignId, address user);

    /// @dev `Approval Transfer`
    event CampaignUserDataTransferred(
        uint256 indexed campaignId,
        address oldAddress,
        address newAddress,
        address sender
    );

    /// @dev `Contribution Events`
    event ContributionMade(
        uint256 indexed campaignId,
        uint256 amount,
        address sender
    );
    event ContributionWithdrawn(
        uint256 indexed campaignId,
        uint256 amount,
        address sender
    );
    event TargetMet(uint256 indexed campaignId, uint256 amount, address sender);

    /// @dev `Request Events`
    event RequestAdded(
        uint256 indexed requestId,
        uint256 campaignId,
        uint256 duration,
        uint256 value,
        address recipient,
        address sender
    );
    event RequestVoided(
        uint256 indexed requestId,
        uint256 campaignId,
        address sender
    );
    event RequestComplete(
        uint256 indexed requestId,
        uint256 campaignId,
        address sender
    );

    /// @dev `Reward Events`
    event RewardCreated(
        uint256 indexed rewardId,
        uint256 campaignId,
        uint256 value,
        uint256 deliveryDate,
        uint256 stock,
        bool active,
        address sender
    );
    event RewardModified(
        uint256 indexed rewardId,
        uint256 campaignId,
        uint256 value,
        uint256 deliveryDate,
        uint256 stock,
        bool active,
        address sender
    );
    event RewardStockIncreased(
        uint256 indexed rewardId,
        uint256 campaignId,
        uint256 count,
        address sender
    );
    event RewardDestroyed(
        uint256 indexed rewardId,
        uint256 campaignId,
        address sender
    );

    /// @dev `Rward Recipient Events`
    event RewardRecipientAdded(
        uint256 indexed rewardId,
        uint256 campaignId,
        uint256 amount,
        address sender
    );
    event RewarderApproval(
        uint256 indexed rewardRecipientId,
        uint256 campaignId,
        bool status,
        address sender
    );
    event RewardRecipientApproval(
        uint256 indexed rewardRecipientId,
        uint256 campaignId,
        address sender
    );

    /// @dev `Vote Events`
    event Voted(uint256 requestId, uint256 campaignId, address sender);
    event VoteCancelled(uint256 requestId, uint256 campaignId, address sender);

    /// @dev `Review Events`
    event CampaignReviewed(
        bool approvalStatus,
        uint256 campaignId,
        address sender
    );

    /// @dev `Campaign State Events`
    event CampaignStateChange(
        uint256 campaignId,
        CAMPAIGN_STATE state,
        address sender
    );

    CampaignFactoryInterface private campaignFactoryContract;

    /// @dev `Request`
    struct Request {
        address payable recipient;
        bool complete;
        uint256 value;
        uint256 approvalCount;
        uint256 duration;
        bool void;
    }
    mapping(uint256 => mapping(address => bool)) requestApprovals;
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
    mapping(uint256 => uint256) public rewardToRewardRecipientCount; // number of users eligible per reward

    /// @dev `RewardRecipient`
    struct RewardRecipient {
        uint256 rewardId;
        address user;
        // bool deliveryConfirmedByCampaign;
        // bool deliveryConfirmedByUser;
    }
    RewardRecipient[] public rewardRecipients;
    mapping(address => uint256) public userRewardCount; // number of rewards owned by a user

    /// @dev `Review`
    uint256 public positiveReviewCount;
    uint256 public reviewCount;
    mapping(address => bool) public reviewed;

    address public root;
    address public acceptedToken;
    bool public allowContributionAfterTargetIsMet;
    uint256 public campaignID;
    uint256 public totalCampaignContribution;
    uint256 public campaignBalance;
    uint256 public minimumContribution;
    uint256 public approversCount;
    uint256 public target;
    uint256 public deadline;
    uint256 public deadlineSetTimes;
    uint256 public finalizedRequestCount;
    uint256 public currentRunningRequest;
    bool public withdrawalsPaused;
    mapping(address => bool) public approvers;
    mapping(address => uint256) public userTotalContribution;

    uint8 private percentBase;
    uint256 private percent;

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

    /// @dev Ensures caller is factory or campaign owner
    modifier adminOrFactory() {
        require(
            CampaignFactoryLib.canManageCampaigns(
                campaignFactoryContract,
                msg.sender
            ) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "admin or factory"
        );
        _;
    }

    /// @dev Ensures the campaign is set to active by campaign owner and approved by factory
    modifier campaignIsActive() {
        bool campaignIsApproved;
        bool campaignIsEnabled;
        (, , campaignIsApproved, campaignIsEnabled) = CampaignFactoryLib
            .campaignInfo(campaignFactoryContract, campaignID);

        require(campaignIsApproved && campaignIsEnabled, "campaign active");
        _;
    }

    /// @dev Ensures campaign isn't approved by factory. Applies unless caller is a campaign manager from factory
    modifier campaignIsNotApproved() {
        bool campaignIsApproved;
        (, , , campaignIsApproved) = CampaignFactoryLib.campaignInfo(
            campaignFactoryContract,
            campaignID
        );

        if (
            !CampaignFactoryLib.canManageCampaigns(
                campaignFactoryContract,
                msg.sender
            )
        ) require(!campaignIsApproved, "campaign approved");

        _;
    }

    /// @dev Ensures a user is verified
    modifier userIsVerified(address _user) {
        bool verified;
        (, verified) = CampaignFactoryLib.userInfo(
            campaignFactoryContract,
            _user
        );
        require(verified, "user not verified");
        _;
    }

    /// @dev Ensures the campaign is within it's deadline, applies only if goal type is fixed
    // modifier withinDeadline() {
    //     require(block.timestamp <= deadline);
    //     _;
    // }

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
        _setupRole(DEFAULT_ADMIN_ROLE, _root);

        campaignFactoryContract = CampaignFactoryInterface(_campaignFactory);
        root = _root;
        campaignState = CAMPAIGN_STATE.GENESIS;
        campaignID = campaignFactoryContract.campaignToID(address(this));
        percentBase = 100;
        percent = percentBase.mul(DecimalMath.UNIT);

        _pause();

        emit CampaignOwnerSet(campaignID, root, msg.sender);
    }

    /**
     * @dev        Transfers campaign ownership from one user to another.
     * @param      _newRoot    Address of the user campaign ownership is being transfered to
     */
    function transferCampaignOwnership(address _newRoot)
        external
        onlyAdmin
        whenNotPaused
        userIsVerified(_newRoot)
    {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _newRoot);

        root = _newRoot;

        emit CampaignOwnershipTransferred(campaignID, _newRoot, msg.sender);
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

        if (approvers[_oldAddress]) {
            // transfer balance
            userTotalContribution[_newAddress] = userTotalContribution[
                _oldAddress
            ];
            userTotalContribution[_oldAddress] = 0;

            // transfer approver account
            approvers[_oldAddress] = false;
            approvers[_newAddress] = true;

            if (userRewardCount[_oldAddress] >= 1) {
                userRewardCount[_newAddress] = userRewardCount[_oldAddress];
                userRewardCount[_oldAddress] = 0;

                for (
                    uint256 index = 0;
                    index < rewardRecipients.length;
                    index++
                ) {
                    if (rewardRecipients[index].user == _oldAddress) {
                        rewardRecipients[index].user = _newAddress;
                    }
                }
            }
        }

        emit CampaignUserDataTransferred(
            campaignID,
            _oldAddress,
            _newAddress,
            msg.sender
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
    ) external adminOrFactory campaignIsNotApproved userIsVerified(msg.sender) {
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
            "contribution too high or low"
        );
        require(campaignFactoryContract.tokensApproved(_token), "B6");
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
            "target too high or low"
        );

        target = _target;
        minimumContribution = _minimumContribution;
        deadline = block.timestamp.add(_duration);
        acceptedToken = _token;
        allowContributionAfterTargetIsMet = _allowContributionAfterTargetIsMet;
        goalType = GOALTYPE(_goalType);

        emit CampaignSettingsUpdated(
            campaignID,
            _minimumContribution,
            _duration,
            _goalType,
            _token,
            msg.sender
        );
    }

    /**
     * @dev        Extends campaign contribution deadline
     * @param      _time    How long until the campaign stops receiving contributions
     */
    function extendDeadline(uint256 _time)
        external
        adminOrFactory
        userIsVerified(msg.sender)
        campaignIsActive
        nonReentrant
        whenNotPaused
    {
        require(
            block.timestamp > deadline &&
                deadlineSetTimes <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "deadlineStrikesAllowed"
                ) &&
                _time <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maxDeadlineExtension"
                ) &&
                _time >=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minDeadlineExtension"
                )
        ); // ensure time exceeds 7 days and less than a day

        deadline = block.timestamp.add(_time);

        // limit ability to increase deadlines
        deadlineSetTimes = deadlineSetTimes.add(1);

        emit CampaignDeadlineExtended(campaignID, _time, msg.sender);
    }

    /**
     * @dev        Sets the number of times the campaign owner can extended deadlines. Restricted to factory
     * @param      _count   Number of times a campaign owner can extend the deadline
     */
    function setDeadlineSetTimes(uint8 _count)
        external
        onlyFactory
        campaignIsActive
        whenNotPaused
    {
        deadlineSetTimes = _count;
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
    ) external adminOrFactory userIsVerified(msg.sender) whenNotPaused {
        require(
            _value >
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minimumContributionAllowed"
                ) &&
                _value <
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumContributionAllowed"
                )
        );
        rewards.push(Reward(_value, _deliveryDate, _stock, true, _active));

        emit RewardCreated(
            rewards.length.sub(1),
            campaignID,
            _value,
            _deliveryDate,
            _stock,
            _active,
            msg.sender
        );
    }

    /**
     * @dev        Modifies a reward by id
     * @param      _rewardId        Reward unique id
     * @param      _value           Reward cost
     * @param      _deliveryDate    Time in which reward will be deliverd to contriutors
     * @param      _stock           Quantity available for dispatch
     * @param      _active          Indicates if contributors can attain the reward
     */
    function modifyReward(
        uint256 _rewardId,
        uint256 _value,
        uint256 _deliveryDate,
        uint256 _stock,
        bool _active
    ) external adminOrFactory userIsVerified(msg.sender) whenNotPaused {
        /**
         * To modify a reward:
         * check reward has no backers
         * check reward exists
         */
        require(
            rewardToRewardRecipientCount[_rewardId] < 1 &&
                rewards[_rewardId].exists,
            "reward has backers or not found"
        );
        require(
            _value >
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minimumContributionAllowed"
                ) &&
                _value <
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumContributionAllowed"
                ),
            "amount too low or high"
        );

        rewards[_rewardId].value = _value;
        rewards[_rewardId].deliveryDate = _deliveryDate;
        rewards[_rewardId].stock = _stock;
        rewards[_rewardId].active = _active;

        emit RewardModified(
            _rewardId,
            campaignID,
            _value,
            _deliveryDate,
            _stock,
            _active,
            msg.sender
        );
    }

    /**
     * @dev        Increases a reward stock count
     * @param      _rewardId        Reward unique id
     * @param      _count           Stock count to increase by
     */
    function increaseRewardStock(uint256 _rewardId, uint256 _count)
        external
        adminOrFactory
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(rewards[_rewardId].exists);
        rewards[_rewardId].stock = rewards[_rewardId].stock.add(_count);

        emit RewardStockIncreased(_rewardId, campaignID, _count, msg.sender);
    }

    /**
     * @dev        Deletes a reward by id
     * @param      _rewardId    Reward unique id
     */
    function destroyReward(uint256 _rewardId)
        external
        adminOrFactory
        userIsVerified(msg.sender)
        whenNotPaused
    {
        // check reward has no backers
        require(
            rewardToRewardRecipientCount[_rewardId] < 1 &&
                rewards[_rewardId].exists
        );

        delete rewards[_rewardId];

        emit RewardDestroyed(_rewardId, campaignID, msg.sender);
    }

    /**
     * @dev        Called by the campaign owner to indicate they delivered the reward to the rewardRecipient
     * @param      _rewardRecipientId  ID to struct containing reward and user to be rewarded
     * @param      _status      Indicates if the delivery was successful or not
     */
    // function campaignSentReward(uint256 _rewardRecipientId, bool _status)
    //     external
    //     campaignIsActive
    //     userIsVerified(msg.sender)
    //     adminOrFactory
    //     whenNotPaused
    // {
    //     require(
    //         rewardToRewardRecipientCount[
    //             rewardRecipients[_rewardRecipientId].rewardId
    //         ] >= 1
    //     );

    //     rewardRecipients[_rewardRecipientId]
    //         .deliveryConfirmedByCampaign = _status;
    //     emit RewarderApproval(
    //         _rewardRecipientId,
    //         msg.sender,
    //         campaignID,
    //         _status
    //     );
    // }

    // /**
    //  * @dev        Called by a user eligible for rewards to indicate they received their reward
    //  * @param      _rewardRecipientId  ID to struct containing reward and user to be rewarded
    //  */
    // function userReceivedCampaignReward(uint256 _rewardRecipientId)
    //     external
    //     campaignIsActive
    //     userIsVerified(msg.sender)
    //     whenNotPaused
    // {
    //     require(
    //         rewardRecipients[_rewardRecipientId].deliveryConfirmedByCampaign &&
    //             !rewardRecipients[_rewardRecipientId].deliveryConfirmedByUser,
    //         "B10"
    //     ); // ensure campaign owner tried to confirm delivery
    //     require(
    //         rewardRecipients[_rewardRecipientId].user == msg.sender &&
    //             userRewardCount[msg.sender] >= 1 &&
    //             approvers[msg.sender],
    //         "B11"
    //     );
    //     rewardRecipients[_rewardRecipientId].deliveryConfirmedByUser = true;
    //     emit RewardRecipientApproval(
    //         _rewardRecipientId,
    //         msg.sender,
    //         campaignID
    //     );
    // }

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
        whenNotPaused
        nonReentrant
    {
        // campaign owner cannot contribute to own campaign
        // token must be accepted
        // contrubution amount must be less than or equal to allowed value from factory
        require(block.timestamp <= deadline);
        require(
            msg.sender != root &&
                _token == acceptedToken &&
                msg.value >= minimumContribution &&
                msg.value <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumContributionAllowed"
                ),
            "not allowed"
        );

        if (!allowContributionAfterTargetIsMet) {
            // check user contribution added to current total contribution doesn't exceed target
            // if it does, calculate the amount to target completion return it back to user to change contribution value
            require(
                msg.value <= target &&
                    totalCampaignContribution.add(msg.value) <= target,
                "exceeds target"
            );
        }

        if (_withReward) {
            require(
                msg.value >= rewards[_rewardId].value &&
                    rewards[_rewardId].stock > 0 &&
                    rewards[_rewardId].exists &&
                    rewards[_rewardId].active,
                "reward not found or active"
            );

            rewardRecipients.push(RewardRecipient(_rewardId, msg.sender));
            userRewardCount[msg.sender] = userRewardCount[msg.sender].add(1);
            rewardToRewardRecipientCount[
                _rewardId
            ] = rewardToRewardRecipientCount[_rewardId].add(1);

            emit RewardRecipientAdded(
                _rewardId,
                campaignID,
                msg.value,
                msg.sender
            );
        }

        if (!approvers[msg.sender]) {
            approversCount = approversCount.add(1);
            approvers[msg.sender] = true;
        }

        totalCampaignContribution = totalCampaignContribution.add(msg.value);
        campaignBalance = campaignBalance.add(msg.value);
        userTotalContribution[msg.sender] = userTotalContribution[msg.sender]
            .add(msg.value);

        // keep track of when target is met
        if (totalCampaignContribution >= target) {
            campaignState = CAMPAIGN_STATE.LIVE;
            emit TargetMet(campaignID, totalCampaignContribution, msg.sender);
        }

        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(acceptedToken),
            msg.sender,
            address(this),
            msg.value
        );

        emit ContributionMade(campaignID, msg.value, msg.sender);
    }

    /**
     * @dev        Allows withdrawal of contribution by a user, works if campaign target isn't met
     * @param      _amount    Amount requested to be withdrawn from contributions
     * @param      _wallet    Address where amount is delivered
     */
    function withdrawOwnContribution(uint256 _amount, address payable _wallet)
        external
        userIsVerified(msg.sender)
        nonReentrant
    {
        require(!withdrawalsPaused);
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
    ) external onlyFactory nonReentrant {
        require(!withdrawalsPaused);
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
        // if the campaign state is neither unsuccessful and in review and there are reviews
        // allow withdrawls
        if (
            campaignState != CAMPAIGN_STATE.UNSUCCESSFUL &&
            campaignState != CAMPAIGN_STATE.REVIEW &&
            reviewCount < 1
        ) {
            require(
                campaignState == CAMPAIGN_STATE.COLLECTION &&
                    finalizedRequestCount < 1,
                "campaign progressing"
            ); // pledge collection ongoing and no request was successful
        }

        // check if person is a contributor
        require(approvers[_user], "not a contributor");

        // totalCampaginContribution - campaginBalance
        // totalCampaignContribution.sub(campaignBalance);

        // calculate % loss between totalCampaginContribution and campaginBalance
        DecimalMath.UFixed memory percentTakenSoFar = DecimalMath.muld(
            DecimalMath.divd(
                totalCampaignContribution.sub(campaignBalance),
                totalCampaignContribution
            ),
            percent
        );
        // calculate % loss of userBalance and subtract loss
        DecimalMath.UFixed memory userLoss = DecimalMath.muld(
            DecimalMath.divd(percentTakenSoFar, percent),
            userTotalContribution[_user]
        );

        // check amount
        // determine user % in totalConribution
        // DecimalMath.UFixed memory ratio = DecimalMath.muld(
        //     DecimalMath.divd(
        //         DecimalMath.toUFixed(userTotalContribution[_user]),
        //         DecimalMath.toUFixed(totalCampaignContribution)
        //     ),
        //     percent
        // );
        // DecimalMath.UFixed memory maximumAllowedWithdrawal = DecimalMath.muld(
        //     DecimalMath.divd(ratio, percent),
        //     totalCampaignContribution
        // );

        require(
            _amount <= userTotalContribution[_user].sub(userLoss.value) &&
                address(_wallet) != address(0),
            "amount exceeds balance"
        );

        // no longer eligible for any reward if campaign is not unsuccessful or in review
        // for record keeping purposes
        if (
            campaignState != CAMPAIGN_STATE.UNSUCCESSFUL ||
            campaignState != CAMPAIGN_STATE.REVIEW
        ) {
            if (userRewardCount[_user] >= 1) {
                userRewardCount[_user] = 0;

                // deduct rewardRecipients count
                for (
                    uint256 index = 0;
                    index < rewardRecipients.length;
                    index++
                ) {
                    rewardToRewardRecipientCount[
                        rewardRecipients[index].rewardId
                    ] = rewardToRewardRecipientCount[
                        rewardRecipients[index].rewardId
                    ].sub(1);
                }
            }

            // mark user as a non contributor
            approvers[_user] = false;

            // reduce approvers count
            approversCount = approversCount.sub(1);
        }

        // decrement total contributions to campaign
        campaignBalance = campaignBalance.sub(_amount);
        totalCampaignContribution = totalCampaignContribution.sub(_amount);

        userTotalContribution[_user] = userTotalContribution[_user].sub(
            _amount
        );

        // transfer to _user
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(acceptedToken),
            _wallet,
            _amount
        );

        emit ContributionWithdrawn(campaignID, _amount, msg.sender);
    }

    /**
     * @dev        Creates a formal request to withdraw funds from user contributions called by the campagn manager or factory
                   Restricted unless target is met and deadline is expired
     * @param      _recipient   Address where requested funds are deposited
     * @param      _value       Amount being requested by the campaign manager
     * @param      _duration    Duration until users aren't able to vote on the request
     */
    function createRequest(
        address payable _recipient,
        uint256 _value,
        uint256 _duration
    )
        external
        adminOrFactory
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(address(_recipient) != address(0));
        require(block.timestamp >= deadline, "deadline not expired");
        if (goalType == GOALTYPE.FIXED) {
            require(
                totalCampaignContribution >= target &&
                    campaignState == CAMPAIGN_STATE.LIVE,
                "target not met"
            );
        }
        require(
            _value >=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minimumRequestAmountAllowed"
                ) &&
                _value <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumRequestAmountAllowed"
                ),
            "amount too low or high"
        ); // ensure request above minimum
        require(
            _duration >=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minRequestDuration"
                ) &&
                _duration <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maxRequestDuration"
                ),
            "duration too low or high"
        ); // request duration should be within factory's specs

        // before creating a new request last request should have expired
        // applies if there's a request before
        if (requestCount >= 1)
            require(
                requests[currentRunningRequest].duration <= block.timestamp,
                "request ongoing"
            );

        requests.push(
            Request(
                _recipient,
                false,
                _value,
                0,
                block.timestamp.add(_duration),
                false
            )
        );
        requestCount = requestCount.add(1);
        currentRunningRequest = requests.length.sub(1);

        emit RequestAdded(
            requests.length.sub(1),
            campaignID,
            _duration,
            _value,
            _recipient,
            msg.sender
        );
    }

    /**
     * @dev        Renders a request void and useless
     * @param      _requestId   ID of request being voided
     */
    function voidRequest(uint256 _requestId)
        external
        adminOrFactory
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(
            !requests[_requestId].void &&
                requestCount == _requestId.add(1) &&
                requests[_requestId].approvalCount < 1 &&
                !requests[_requestId].complete
        ); // request must not be void and must be last made request
        // request must have no votes
        // request should not have been finalized

        requests[_requestId].void = true;
        requests[_requestId].duration = 0;

        emit RequestVoided(_requestId, campaignID, msg.sender);
    }

    /**
     * @dev        Approvers only method which approves spending request issued by the campaign manager or factory
     * @param      _requestId   ID of request being voted on
     */
    function voteOnRequest(uint256 _requestId)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(
            approvers[msg.sender] &&
                !requestApprovals[_requestId][msg.sender] &&
                block.timestamp <= requests[_requestId].duration,
            "approved or not an approver"
        );
        require(!requests[_requestId].void, "request voided");

        requestApprovals[_requestId][msg.sender] = true;

        requests[_requestId].approvalCount = requests[_requestId]
            .approvalCount
            .add(1);

        emit Voted(_requestId, campaignID, msg.sender);
    }

    /**
     * @dev        Approvers only method which cancels initial vote on a request
     * @param      _requestId   ID of request being voted on
     */
    function cancelVote(uint256 _requestId)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(
            approvers[msg.sender] &&
                block.timestamp <= requests[_requestId].duration
        );
        requestApprovals[_requestId][msg.sender] = false;

        requests[_requestId].approvalCount = requests[_requestId]
            .approvalCount
            .sub(1);

        emit VoteCancelled(_requestId, campaignID, msg.sender);
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
        // more than 50% of approvers to finalize
        DecimalMath.UFixed memory percentOfRequestApprovals = DecimalMath.muld(
            DecimalMath.divd(
                DecimalMath.toUFixed(request.approvalCount),
                DecimalMath.toUFixed(approversCount)
            ),
            percent
        );
        uint256 thresholdMark = 51;
        require(
            percentOfRequestApprovals.value >=
                thresholdMark.mul(DecimalMath.UNIT) &&
                !request.complete &&
                !request.void
        );

        DecimalMath.UFixed memory factoryFee = DecimalMath.muld(
            DecimalMath.divd(
                CampaignFactoryLib.factoryPercentFee(
                    campaignFactoryContract,
                    campaignID
                ),
                percent
            ),
            request.value
        );

        uint256[2] memory payouts = [
            request.value.sub(factoryFee.value),
            factoryFee.value
        ];
        address payable[2] memory addresses = [
            request.recipient,
            campaignFactoryContract.factoryWallet()
        ];

        request.complete = true;
        finalizedRequestCount = finalizedRequestCount.add(1);
        campaignBalance = campaignBalance.sub(request.value);

        campaignFactoryContract.receiveCampaignCommission(0, address(this));

        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(acceptedToken),
                addresses[i],
                payouts[i]
            );
        }

        emit RequestComplete(_requestId, campaignID, msg.sender);
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
        // check no pending request
        // check campaign state is running
        //require(campaignState == CAMPAIGN_STATE.LIVE);
        require(requestCount >= 1 && requests[currentRunningRequest].complete);

        campaignState = CAMPAIGN_STATE.REVIEW;
        _pause();

        emit CampaignStateChange(campaignID, CAMPAIGN_STATE.REVIEW, msg.sender);
    }

    /**
     * @dev        User acknowledgement of review state enabled by the campaign owner
     * @param      _approval      Indicates user approval of the campaign
     */
    function reviewCampaignPerformance(bool _approval)
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

        if (_approval) {
            positiveReviewCount = positiveReviewCount.add(1);
        }

        reviewCount = reviewCount.add(1);

        emit CampaignReviewed(_approval, campaignID, msg.sender);
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
        DecimalMath.UFixed memory percentOfApproversCount = DecimalMath.muld(
            DecimalMath.divd(
                CampaignFactoryLib
                    .getCampaignFactoryConfig(
                        campaignFactoryContract,
                        "reviewThresholdMark"
                    )
                    .mul(DecimalMath.UNIT),
                percent
            ),
            approversCount
        );
        require(
            positiveReviewCount >= percentOfApproversCount.value &&
                campaignState == CAMPAIGN_STATE.REVIEW
        );
        campaignState = CAMPAIGN_STATE.COMPLETE;

        emit CampaignStateChange(
            campaignID,
            CAMPAIGN_STATE.COMPLETE,
            msg.sender
        );
    }

    /// @dev Called by an approver to report a campaign to factory. Campaign must be in collection or live state
    // function reportCampaign()
    //     external
    //     userIsVerified(msg.sender)
    //     campaignIsActive
    //     whenNotPaused
    // {
    //     require(
    //         (approvers[msg.sender] &&
    //             campaignState == CAMPAIGN_STATE.COLLECTION) ||
    //             campaignState == CAMPAIGN_STATE.LIVE
    //     );
    //     emit CampaignReported(campaignID, msg.sender);
    // }

    /// @dev Changes campaign state
    function setCampaignState(uint256 _state) external onlyFactory {
        campaignState = CAMPAIGN_STATE(_state);

        emit CampaignStateChange(
            campaignID,
            CAMPAIGN_STATE(_state),
            msg.sender
        );
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
