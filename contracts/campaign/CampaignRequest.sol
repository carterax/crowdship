// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./CampaignFactory.sol";
import "./Campaign.sol";
import "./CampaignVote.sol";
import "../utils/Roles.sol";

import "../libraries/contracts/CampaignFactoryLib.sol";

import "../interfaces/ICampaignFactory.sol";
import "../interfaces/ICampaign.sol";
import "../interfaces/ICampaignVote.sol";

import "../libraries/math/DecimalMath.sol";

contract CampaignRequest is
    Initializable,
    Roles,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    /// @dev `Request Events`
    event RequestAdded(
        uint256 indexed requestId,
        uint256 duration,
        uint256 value,
        string hashedRequest,
        address recipient
    );
    event RequestVoided(uint256 indexed requestId);

    /// @dev `Request`
    struct Request {
        address payable recipient;
        uint256 value;
        uint256 approvalCount;
        uint256 againstCount;
        uint256 abstainedCount;
        uint256 duration;
        string hashedRequest;
        bool complete;
        bool void;
    }
    mapping(uint256 => Request) public requests;

    uint256 public requestCount;
    uint256 public finalizedRequestCount;
    uint256 public currentRunningRequest;

    CampaignFactory public campaignFactoryContract;
    Campaign public campaignContract;

    ICampaign public campaignInterface;
    ICampaignFactory public campaignFactoryInterface;

    /// @dev Ensures caller is campaign owner
    modifier hasRole(bytes32 _permission, address _user) {
        require(campaignInterface.isAllowed(_permission, _user));
        _;
    }

    /// @dev Ensures caller is a verified user
    modifier userIsVerified(address _user) {
        bool verified;
        (, , verified) = CampaignFactoryLib.userInfo(
            campaignFactoryInterface,
            _user
        );
        require(verified, "unverified");
        _;
    }

    /**
     * @dev        Constructor
     * @param      _campaignFactory     Address of factory
     * @param      _campaign            Address of campaign contract this contract belongs to
     */
    function __CampaignRequest_init(
        CampaignFactory _campaignFactory,
        Campaign _campaign
    ) public initializer {
        campaignFactoryContract = _campaignFactory;
        campaignContract = _campaign;

        campaignFactoryInterface = ICampaignFactory(address(_campaignFactory));
        campaignInterface = ICampaign(address(_campaign));
    }

    /**
     * @dev        Creates a formal request to withdraw funds from user contributions called by the campagn manager
                   Restricted unless target is met and deadline is expired
     * @param      _recipient       Address where requested funds are deposited
     * @param      _value           Amount being requested by the campaign manager
     * @param      _duration        Duration until users aren't able to vote on the request
     * @param      _hashedRequest   CID reference of the request on IPFS
     */
    function createRequest(
        address payable _recipient,
        uint256 _value,
        uint256 _duration,
        string memory _hashedRequest
    ) external hasRole(CREATE_REQUEST, msg.sender) whenNotPaused {
        require(address(_recipient) != address(0));

        if (
            campaignInterface.totalCampaignContribution() <
            campaignInterface.target()
        )
            require(
                block.timestamp >= campaignInterface.deadline(),
                "deadline not expired"
            );

        // check if goaltype is FIXED
        if (
            campaignInterface.goalType() ==
            campaignInterface.getCampaignGoalType(0)
        ) {
            require(
                campaignInterface.totalCampaignContribution() >=
                    campaignInterface.target() &&
                    campaignInterface.campaignState() ==
                    campaignInterface.getCampaignState(1),
                "target unmet"
            );
        }
        require(
            _value >=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryInterface,
                    "minimumRequestAmountAllowed"
                ) &&
                _value <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryInterface,
                    "maximumRequestAmountAllowed"
                ),
            "amount deficit"
        );
        require(
            _value <= campaignInterface.campaignBalance(),
            "amount over balance"
        );
        require(
            _duration >=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryInterface,
                    "minRequestDuration"
                ) &&
                _duration <=
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryInterface,
                    "maxRequestDuration"
                ),
            "duration deficit"
        );

        // before creating a new request last request should be complete
        // applies if there's a request before
        if (requestCount >= 1)
            require(
                requests[currentRunningRequest].complete,
                "request ongoing"
            );

        requestCount = requestCount.add(1);
        currentRunningRequest = requestCount.sub(1);
        requests[currentRunningRequest] = Request(
            _recipient,
            _value,
            0,
            0,
            0,
            block.timestamp.add(_duration),
            _hashedRequest,
            false,
            false
        );

        emit RequestAdded(
            currentRunningRequest,
            _duration,
            _value,
            _hashedRequest,
            _recipient
        );
    }

    /**
     * @dev        Renders a request void and useless
     * @param      _requestId   ID of request being voided
     */
    function voidRequest(uint256 _requestId)
        external
        hasRole(VOID_REQUEST, msg.sender)
        whenNotPaused
    {
        // request must not be void
        // request must have no votes
        // request should not have been finalized
        require(!requests[_requestId].void, "voided");
        require(requests[_requestId].approvalCount < 1, "has approvals");
        // require(!requests[_requestId].complete, "already finalized");

        requests[_requestId].void = true;

        emit RequestVoided(_requestId);
    }

    /**
     * @dev        Finalizes vote on a request, called only from voting contract
     * @param      _requestId   ID of request being finalized
     * @param      _support     An integer of 0 for against, 1 for in-favor, and 2 for abstain
     */
    function signRequestVote(uint256 _requestId, uint256 _support) external {
        require(
            campaignInterface.campaignVoteContract() == msg.sender,
            "forbidden"
        );
        require(
            block.timestamp <= requests[_requestId].duration,
            "request expired"
        );
        require(!requests[_requestId].void, "voided");

        if (_support == 0) {
            requests[_requestId].againstCount = requests[_requestId]
                .againstCount
                .add(1);
        } else if (_support == 1) {
            requests[_requestId].approvalCount = requests[_requestId]
                .approvalCount
                .add(1);
        } else {
            requests[_requestId].abstainedCount = requests[_requestId]
                .abstainedCount
                .add(1);
        }
    }

    /**
     * @dev        Finalizes vote cancellation, called only from the voting contract
     * @param      _requestId   ID of request whose vote is being cancelled
     */
    function cancelVoteSignature(uint256 _requestId) external {
        require(
            campaignInterface.campaignVoteContract() == msg.sender,
            "forbidden"
        );
        require(
            block.timestamp <= requests[_requestId].duration,
            "request expired"
        );

        ICampaignVote campaignVote = ICampaignVote(
            campaignInterface.campaignVoteContract()
        );

        uint8 support;
        (, support, , , , ) = campaignVote.votes(msg.sender, _requestId);

        if (support == 0) {
            requests[_requestId].againstCount = requests[_requestId]
                .againstCount
                .sub(1);
        } else if (support == 1) {
            requests[_requestId].approvalCount = requests[_requestId]
                .approvalCount
                .sub(1);
        } else {
            requests[_requestId].abstainedCount = requests[_requestId]
                .abstainedCount
                .sub(1);
        }
    }

    /**
     * @dev        Request finalization called only from the campaign contract
     * @param      _requestId      ID of request whose withdrawal is being finalized
     */
    function signRequestFinalization(uint256 _requestId)
        external
        whenNotPaused
        nonReentrant
    {
        require(address(campaignContract) == msg.sender, "forbidden");

        Request storage request = requests[_requestId];
        // more than 50% of approvers to finalize
        DecimalMath.UFixed memory percentOfRequestApprovals = DecimalMath.muld(
            DecimalMath.divd(
                DecimalMath.toUFixed(request.approvalCount),
                DecimalMath.toUFixed(campaignInterface.approversCount())
            ),
            campaignInterface.percent()
        );
        require(
            percentOfRequestApprovals.value >=
                CampaignFactoryLib
                    .getCampaignFactoryConfig(
                        campaignFactoryInterface,
                        "requestFinalizationThreshold"
                    )
                    .mul(DecimalMath.UNIT),
            "approval deficit"
        );
        require(!request.complete, "finalized");

        DecimalMath.UFixed memory factoryFee = DecimalMath.muld(
            DecimalMath.divd(
                CampaignFactoryLib.factoryPercentFee(
                    campaignFactoryInterface,
                    campaignContract
                ),
                campaignInterface.percent()
            ),
            request.value
        );

        uint256[2] memory payouts = [
            request.value.sub(factoryFee.value),
            factoryFee.value
        ];
        address payable[2] memory addresses = [
            request.recipient,
            campaignFactoryInterface.factoryWallet()
        ];

        request.complete = true;
        finalizedRequestCount = finalizedRequestCount.add(1);

        CampaignFactoryLib.sendCommissionFee(
            campaignFactoryInterface,
            campaignContract,
            factoryFee.value
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(campaignInterface.acceptedToken()),
                addresses[i],
                payouts[i]
            );
        }
    }
}
