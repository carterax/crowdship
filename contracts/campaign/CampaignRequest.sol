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

import "../libraries/contracts/CampaignFactoryLib.sol";

import "../interfaces/ICampaignFactory.sol";
import "../interfaces/ICampaign.sol";

import "../libraries/math/DecimalMath.sol";

contract CampaignRequest is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    /// @dev `Request Events`
    event RequestAdded(
        uint256 indexed requestId,
        uint256 duration,
        uint256 value,
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
        bool complete;
        bool void;
    }
    Request[] public requests;

    uint256 public requestCount;
    uint256 public finalizedRequestCount;
    uint256 public currentRunningRequest;
    uint256 public campaignID;

    ICampaignFactory public campaignFactoryContract;
    ICampaign public campaignContract;

    modifier onlyAdmin(address _user) {
        require(campaignContract.isCampaignAdmin(_user), "not campaign admin");
        _;
    }

    modifier userIsVerified(address _user) {
        bool verified;
        (, verified) = CampaignFactoryLib.userInfo(
            campaignFactoryContract,
            _user
        );
        require(verified, "unverified");
        _;
    }

    /// @dev Ensures caller is a registered campaign contract from factory
    modifier onlyRegisteredCampaigns() {
        address campaignAddress;

        (campaignAddress, , ) = CampaignFactoryLib.campaignInfo(
            campaignFactoryContract,
            campaignID
        );

        require(campaignAddress == msg.sender, "forbidden");
        _;
    }

    function __CampaignRequest_init(
        CampaignFactory _campaignFactory,
        Campaign _campaign,
        uint256 _campaignId
    ) public initializer {
        campaignFactoryContract = ICampaignFactory(address(_campaignFactory));
        campaignContract = ICampaign(address(_campaign));

        campaignID = _campaignId;
    }

    /**
     * @dev        Creates a formal request to withdraw funds from user contributions called by the campagn manager
                   Restricted unless target is met and deadline is expired
     * @param      _recipient   Address where requested funds are deposited
     * @param      _value       Amount being requested by the campaign manager
     * @param      _duration    Duration until users aren't able to vote on the request
     */
    function createRequest(
        address payable _recipient,
        uint256 _value,
        uint256 _duration
    ) external onlyAdmin(msg.sender) whenNotPaused {
        require(address(_recipient) != address(0));

        if (
            campaignContract.totalCampaignContribution() <
            campaignContract.target()
        )
            require(
                block.timestamp >= campaignContract.deadline(),
                "deadline not expired"
            );

        if (
            campaignContract.goalType() ==
            campaignContract.getCampaignGoalType()
        ) {
            require(
                campaignContract.totalCampaignContribution() >=
                    campaignContract.target() &&
                    campaignContract.campaignState() ==
                    campaignContract.getCampaignState(1),
                "target unmet"
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
            "amount deficit"
        );
        require(
            _value <= campaignContract.campaignBalance(),
            "amount over balance"
        );
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
            "duration deficit"
        );

        // before creating a new request last request should be complete
        // applies if there's a request before
        if (requestCount >= 1)
            require(
                requests[currentRunningRequest].complete,
                "request ongoing"
            );

        requests.push(
            Request(
                _recipient,
                _value,
                0,
                0,
                0,
                block.timestamp.add(_duration),
                false,
                false
            )
        );
        requestCount = requestCount.add(1);
        currentRunningRequest = requests.length.sub(1);

        emit RequestAdded(
            requests.length.sub(1),
            _duration,
            _value,
            _recipient
        );
    }

    /**
     * @dev        Renders a request void and useless
     * @param      _requestId   ID of request being voided
     */
    function voidRequest(uint256 _requestId)
        external
        onlyAdmin(msg.sender)
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

    function signRequestVote(uint256 _requestId, uint256 _support) external {
        require(campaignContract.campaignVoteContract() == msg.sender);
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

    function cancelVoteSignature(uint256 _requestId) external {
        require(campaignContract.campaignVoteContract() == msg.sender);
        require(
            block.timestamp <= requests[_requestId].duration,
            "request expired"
        );

        CampaignVote campaignVote = CampaignVote(
            campaignContract.campaignVoteContract()
        );
        uint256 voteId = campaignVote.voteId(msg.sender, _requestId);
        uint8 support;
        (support, , , ) = campaignVote.votes(voteId);

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
     * @dev        Withdrawal method called only when a request receives the right amount votes
     * @param      _requestId      ID of request being withdrawn
     */
    function finalizeRequest(uint256 _requestId)
        external
        onlyRegisteredCampaigns
        whenNotPaused
        nonReentrant
    {
        Request storage request = requests[_requestId];
        // more than 50% of approvers to finalize
        DecimalMath.UFixed memory percentOfRequestApprovals = DecimalMath.muld(
            DecimalMath.divd(
                DecimalMath.toUFixed(request.approvalCount),
                DecimalMath.toUFixed(campaignContract.approversCount())
            ),
            campaignContract.percent()
        );
        require(
            percentOfRequestApprovals.value >=
                CampaignFactoryLib
                    .getCampaignFactoryConfig(
                        campaignFactoryContract,
                        "requestFinalizationThreshold"
                    )
                    .mul(DecimalMath.UNIT),
            "approval deficit"
        );
        require(!request.complete, "finalized");

        DecimalMath.UFixed memory factoryFee = DecimalMath.muld(
            DecimalMath.divd(
                CampaignFactoryLib.factoryPercentFee(
                    campaignFactoryContract,
                    campaignID
                ),
                campaignContract.percent()
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

        CampaignFactoryLib.sendCommissionFee(
            campaignFactoryContract,
            address(this),
            factoryFee.value
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(campaignContract.acceptedToken()),
                addresses[i],
                payouts[i]
            );
        }
    }
}
