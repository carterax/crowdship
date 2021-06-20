// contracts/Campaign.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./utils/AccessControl.sol";

abstract contract CampaignFactoryInterface {
    struct CampaignInfo {
        address campaign;
        bool featured;
        bool active;
        bool approved;
    }
    CampaignInfo[] public deployedCampaigns;
    mapping(address => uint256) public campaignToID;

    mapping(address => bool) public userIsVerified;
}

// setup default roles
// assign admin from factory as default role
contract Campaign is Initializable, AccessControl {
    using SafeMathUpgradeable for uint256;

    event ContributionMade(address approver, uint256 value);

    /// @dev `Request`
    struct Request {
        string description;
        address payable recepient;
        bool complete;
        uint256 value;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }
    Request[] public requests;

    /// @dev `Reward`
    struct Reward {
        uint256 value;
        string deliveryDate;
        uint256 stock;
        bool exists;
        bool active;
        mapping(address => bool) rewardee; // address being rewarded
        mapping(address => bool) rewarded; // address is rewarded
    }
    mapping(uint256 => uint256) rewardeeCount;
    Reward[] public rewards;

    CampaignFactoryInterface campaignFactoryContract;

    address public root;

    uint256 public category;
    uint256 public minimumContribution;
    uint256 public approversCount;
    bool canContributeAfterDeadline;
    string deadline;

    mapping(address => bool) public approvers;

    modifier campaignIsActive() {
        bool campaignIsEnabled;
        bool campaignIsApproved;

        (, , campaignIsEnabled, campaignIsApproved) = campaignFactoryContract
            .deployedCampaigns(
            campaignFactoryContract.campaignToID(address(this))
        );

        require(
            campaignIsApproved &&
                campaignIsEnabled &&
                canContributeAfterDeadline &&
                msg.value >= minimumContribution
        );
        _;
    }

    modifier canVoteOrContribute() {
        require(campaignFactoryContract.userIsVerified(msg.sender));
        _;
    }

    modifier canApproveRequest(uint256 _requestId) {
        require(
            approvers[msg.sender] && !requests[_requestId].approvals[msg.sender]
        );
        _;
    }

    /// @dev constructor
    function __Campaign_init(
        address _campaignFactory,
        address _root,
        uint256 _category,
        uint256 _minimum
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _root);

        campaignFactoryContract = CampaignFactoryInterface(_campaignFactory);

        root = _root;
        category = _category;
        minimumContribution = _minimum;
    }

    function setCampaignDetails(
        uint256 _category,
        uint256 _minimumContribution,
        bool _canContributeAfterDeadline,
        string memory _deadline
    ) external onlyAdmin {
        category = _category;
        minimumContribution = _minimumContribution;
        canContributeAfterDeadline = _canContributeAfterDeadline;
        deadline = _deadline;
    }

    function createRequest(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) external onlyAdmin {
        Request storage request = requests[requests.length.add(1)];
        request.description = _description;
        request.recepient = _recipient;
        request.complete = false;
        request.value = _value;
        request.approvalCount = 0;
    }

    function createReward(
        uint256 _value,
        string memory _deliveryDate,
        uint256 _stock,
        bool _active
    ) external onlyAdmin {
        Reward storage newReward = rewards[rewards.length.add(1)];

        newReward.value = _value;
        newReward.deliveryDate = _deliveryDate;
        newReward.stock = _stock;
        newReward.exists = true;
        newReward.active = _active;
    }

    function contribute() public payable campaignIsActive canVoteOrContribute {
        _contribute();
    }

    function contributeWithReward(uint256 _rewardId)
        public
        payable
        campaignIsActive
        canVoteOrContribute
    {
        if (
            rewards[_rewardId].value == msg.value &&
            rewards[_rewardId].stock > 0 &&
            rewards[_rewardId].exists &&
            rewards[_rewardId].active
        ) {
            rewards[_rewardId].rewardee[msg.sender] = true;
            rewardeeCount[_rewardId] = rewardeeCount[_rewardId].add(1);
        }

        _contribute();
    }

    function approveRequest(uint256 _requestId)
        public
        canApproveRequest(_requestId)
    {
        requests[_requestId].approvals[msg.sender] = true;

        requests[_requestId].approvalCount.add(1);
    }

    function finalizeRequest(uint256 index) public onlyAdmin {
        Request storage request = requests[index];
        require(
            request.approvalCount > (approversCount.div(2)) && !request.complete
        );

        request.recepient.transfer(request.value);
        request.complete = true;
    }

    function _contribute() private {
        approvers[msg.sender] = true;

        if (!approvers[msg.sender]) {
            approversCount.add(1);
        }
    }

    function getRequestCount() public view returns (uint256) {
        return requests.length;
    }

    function getRewardCount() public view returns (uint256) {
        return rewards.length;
    }

    function destroyReward(uint256 _rewardId) public onlyAdmin {
        require(rewards[_rewardId].exists);

        // set rewardee count to 0
        rewardeeCount[_rewardId] = 0;

        delete rewards[_rewardId];
    }
}
