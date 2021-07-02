// contracts/Campaign.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

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
        ONGOING,
        REVIEW,
        COMPLETE
    }
    CAMPAIGN_STATE public campaignState;

    event ContributionReceived(
        address contributor,
        address token,
        uint256 amount
    );

    CampaignFactoryInterface campaignFactoryContract;

    address public root;
    address public acceptedToken;

    /// @dev `Vote`
    struct Vote {
        bool approved;
        bool voted;
        string comment;
        uint256 created;
    }

    /// @dev `Request`
    struct Request {
        string description;
        address payable recepient;
        bool complete;
        uint256 value;
        uint256 approvalCount;
        uint256 disapprovalCount;
        mapping(address => Vote) votes;
    }
    Request[] public requests;

    /// @dev `Reward`
    struct Reward {
        uint256 value;
        uint256 deliveryDate;
        bytes32[] inclusions;
        uint256 stock;
        bool exists;
        bool active;
        mapping(address => bool) rewardee; // address being rewarded
        mapping(address => bool) rewarded; // address is rewarded
    }
    Reward[] public rewards;
    mapping(address => uint256[]) userRewardIds;
    mapping(uint256 => uint256) rewardeeCount;

    /// @dev `Review`
    struct Review {
        uint256 rating;
        uint256 createdAt;
        string comment;
    }
    Review[] public reviews;
    mapping(address => bool) public reviewed;

    uint256 public totalCampaignContribution;
    uint256 public minimumContribution;
    uint256 public approversCount;
    uint256 public target;
    uint256 public deadline;
    uint256 public deadlineSetTimes;
    bool public requestOngoing;
    mapping(address => bool) userAskedForRefund;
    mapping(address => bool) public approvers;
    mapping(address => uint256) public userTotalContribution;
    mapping(address => uint256) public userBalance;

    modifier onlyFactory() {
        require(
            campaignFactoryContract.canManageCampaigns(msg.sender),
            "only factory allowed"
        );
        _;
    }

    modifier adminOrFactory() {
        require(
            campaignFactoryContract.canManageCampaigns(msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "only admin or factory allowed"
        );
        _;
    }

    modifier campaignIsActive() {
        bool campaignIsEnabled;
        bool campaignIsApproved;

        (, , campaignIsEnabled, campaignIsApproved) = campaignFactoryContract
        .deployedCampaigns(campaignFactoryContract.campaignToID(address(this)));

        require(
            campaignIsApproved && campaignIsEnabled,
            "campaign isn't active"
        );
        _;
    }

    modifier userIsVerified(address _user) {
        bool userVerified;

        (, , , , , userVerified, ) = campaignFactoryContract.users(
            campaignFactoryContract.userID(_user)
        );
        require(userVerified, "user isn't verified");
        _;
    }

    modifier canApproveRequest(uint256 _requestId) {
        require(
            approvers[msg.sender] &&
                !requests[_requestId].votes[msg.sender].voted,
            "cannot approve request"
        );
        _;
    }

    modifier deadlineIsUp() {
        if (goalType == GOALTYPE.FIXED) {
            require(block.timestamp <= deadline, "deadline has expired");
        }
        _;
    }

    modifier targetIsMet() {
        if (goalType == GOALTYPE.FIXED) {
            require(totalCampaignContribution == target, "goal target smashed");
        }
        _;
    }

    /// @dev constructor
    function __Campaign_init(
        address _campaignFactory,
        address _root,
        address _acceptedToken,
        uint256 _minimum
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _root);

        campaignFactoryContract = CampaignFactoryInterface(_campaignFactory);

        root = _root;
        minimumContribution = _minimum;
        goalType = GOALTYPE.FIXED;
        campaignState = CAMPAIGN_STATE.ONGOING;
        acceptedToken = _acceptedToken;

        _pause();
    }

    function setCampaignDetails(uint256 _target, uint256 _minimumContribution)
        external
        adminOrFactory
        campaignIsActive
        whenNotPaused
        nonReentrant
    {
        target = _target;
        minimumContribution = _minimumContribution;
    }

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
    }

    function extendDeadline(uint256 _time)
        external
        adminOrFactory
        campaignIsActive
        whenNotPaused
        nonReentrant
    {
        require(block.timestamp > deadline, "deadline still active");
        require(
            deadlineSetTimes <=
                campaignFactoryContract.deadlineStrikesAllowed(),
            "not allowed to increase deadline"
        );

        // check if time exceeds 7 days and less than a day
        if (
            _time < campaignFactoryContract.maxDeadline() ||
            _time > campaignFactoryContract.minDeadline()
        ) {
            deadline = _time;

            // limit ability to increase deadlines
            deadlineSetTimes = deadlineSetTimes.add(1);
        }
    }

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

    function createRequest(
        string memory _description,
        address payable _recipient,
        uint256 _value
    )
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
        request.description = _description;
        request.recepient = _recipient;
        request.complete = false;
        request.value = _value;
        request.approvalCount = 0;

        requestOngoing = true;
    }

    function getRequestCount() external view returns (uint256) {
        return requests.length;
    }

    function createReward(
        uint256 _value,
        uint256 _deliveryDate,
        uint256 _stock,
        bytes32[] memory _inclusions,
        bool _active
    ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant {
        Reward storage newReward = rewards[rewards.length.add(1)];
        newReward.value = _value;
        newReward.deliveryDate = _deliveryDate;
        newReward.stock = _stock;
        newReward.exists = true;
        newReward.active = _active;
        newReward.inclusions = _inclusions;
    }

    function editReward(
        uint256 _id,
        uint256 _value,
        uint256 _deliveryDate,
        uint256 _stock,
        bytes32[] memory _inclusions,
        bool _active
    ) external adminOrFactory campaignIsActive whenNotPaused nonReentrant {
        require(rewards[_id].exists);
        rewards[_id].value = _value;
        rewards[_id].deliveryDate = _deliveryDate;
        rewards[_id].stock = _stock;
        rewards[_id].active = _active;
        rewards[_id].inclusions = _inclusions;
    }

    function destroyReward(uint256 _rewardId)
        external
        adminOrFactory
        campaignIsActive
        whenNotPaused
        nonReentrant
    {
        require(rewards[_rewardId].exists);

        // set rewardee count to 0
        rewardeeCount[_rewardId] = 0;

        delete rewards[_rewardId];
    }

    function getRewardCount() external view returns (uint256) {
        return rewards.length;
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
        require(_token == acceptedToken, "Not accepted");
        require(
            msg.value >= minimumContribution,
            "amount doesn't meet minimum requirement"
        );

        _contribute();

        if (_withReward) {
            require(
                rewards[_rewardId].value == msg.value &&
                    rewards[_rewardId].stock > 0 &&
                    rewards[_rewardId].exists &&
                    rewards[_rewardId].active,
                "reward not available"
            );

            rewards[_rewardId].rewardee[msg.sender] = true;
            rewardeeCount[_rewardId] = rewardeeCount[_rewardId].add(1);
            userRewardIds[msg.sender].push(_rewardId);
        }

        emit ContributionReceived(msg.sender, acceptedToken, msg.value);
    }

    function _contribute() private {
        IERC20Upgradeable(acceptedToken).transferFrom(
            msg.sender,
            address(this),
            msg.value
        );

        approvers[msg.sender] = true;

        if (!approvers[msg.sender]) {
            approversCount.add(1);
        }

        if (userAskedForRefund[msg.sender]) {
            userAskedForRefund[msg.sender] = false;
        }

        totalCampaignContribution = totalCampaignContribution.add(msg.value);
        userTotalContribution[msg.sender] = userTotalContribution[msg.sender]
        .add(msg.value);
        userBalance[msg.sender] = userBalance[msg.sender].add(msg.value);
        campaignFactoryContract.addCampaignToUser(address(this));
    }

    function pullOwnContribution(uint256 _amount)
        external
        campaignIsActive
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        // check if person is a contributor
        require(approvers[msg.sender], "not a contributor");
        require(_amount <= userBalance[msg.sender], "amount exceeds balance");

        // check if user has reward
        // remove member from persons meant to receive rewards
        // decrement rewardeeCount
        for (
            uint256 index = 0;
            index < userRewardIds[msg.sender].length;
            index++
        ) {
            rewards[userRewardIds[msg.sender][index]].rewardee[
                msg.sender
            ] = false;
            rewardeeCount[userRewardIds[msg.sender][index]].sub(1);
        }

        // set userrewardIds mapping to empty
        uint256[] memory empty;
        userRewardIds[msg.sender] = empty;

        // mark user as a none contributor
        approvers[msg.sender] = false;

        // reduce approvers count
        approversCount.sub(1);

        // decrement total contributions to campaign
        totalCampaignContribution = totalCampaignContribution.sub(_amount);

        // transfer to msg.sender
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed.");

        userBalance[msg.sender].sub(_amount);
        userTotalContribution[msg.sender].sub(_amount);
        userAskedForRefund[msg.sender] = true;
    }

    function voteOnRequest(
        uint256 _requestId,
        bool _vote,
        string memory _comment
    )
        external
        campaignIsActive
        canApproveRequest(_requestId)
        userIsVerified(msg.sender)
        whenNotPaused
        nonReentrant
    {
        requests[_requestId].votes[msg.sender].approved = _vote;
        requests[_requestId].votes[msg.sender].comment = _comment;
        requests[_requestId].votes[msg.sender].voted = true;
        requests[_requestId].votes[msg.sender].created = block.timestamp;

        // determine user % holdings in the pool
        uint256 percentageHolding = userTotalContribution[msg.sender]
        .mul(100)
        .div(address(this).balance);

        // subtract % holding * request value from user total balance
        userBalance[msg.sender] = userTotalContribution[msg.sender].sub(
            percentageHolding.mul(requests[_requestId].value).div(100)
        );

        if (_vote) {
            requests[_requestId].approvalCount.add(1);
        } else {
            requests[_requestId].disapprovalCount.add(1);
        }
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
                !request.complete,
            "votes not enough"
        );

        // get factory cut
        uint256 factoryCutPercentage = campaignFactoryContract
        .factoryCutPercentage();
        uint256 factoryCut = request.value.sub(
            factoryCutPercentage.mul(request.value).div(100)
        );
        uint256 requestCut = request.value.sub(factoryCut);

        (bool success, ) = request.recepient.call{value: requestCut}("");
        require(success, "Transfer to request recepient failed.");

        campaignFactoryContract.receiveCampaignCut(factoryCut, address(this));

        request.complete = true;
        requestOngoing = false;
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
        require(requests.length > 1, "no requests yet");

        // check balance is 0
        require(address(this).balance == 0, "contract still has funds");

        // check no pending request
        require(!requestOngoing, "request pending");

        // check campaign state is running
        require(campaignState == CAMPAIGN_STATE.ONGOING);
        campaignState = CAMPAIGN_STATE.REVIEW;
        _pause();
    }

    function reviewCampaignPerformance(uint256 _rating, string memory _comment)
        external
        userIsVerified(msg.sender)
        campaignIsActive
        nonReentrant
        whenPaused
    {
        require(campaignState == CAMPAIGN_STATE.REVIEW);
        require(_rating <= 5 && _rating >= 1);
        require(!reviewed[msg.sender]);
        require(approvers[msg.sender]);

        reviews.push(Review(_rating, block.timestamp, _comment));
        reviewed[msg.sender] = true;
    }

    function getCampaignRating()
        external
        whenPaused
        nonReentrant
        returns (uint256)
    {
        require(campaignState == CAMPAIGN_STATE.REVIEW);
        uint256 totalRating;
        for (uint256 index = 0; index < reviews.length; index++) {
            totalRating.add(reviews[index].rating);
        }

        return totalRating;
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
            reviews.length >= approversCount.mul(80).div(100) &&
                campaignState == CAMPAIGN_STATE.REVIEW
        );
        campaignState = CAMPAIGN_STATE.COMPLETE;
    }

    function unPauseCampaign() external whenPaused onlyFactory nonReentrant {
        _unpause();
    }

    function pauseCampaign() external whenNotPaused onlyFactory nonReentrant {
        _pause();
    }
}
