// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./CampaignFactory.sol";
import "./Campaign.sol";

import "../interfaces/ICampaignFactory.sol";
import "../interfaces/ICampaign.sol";

import "../libraries/contracts/CampaignFactoryLib.sol";
import "../libraries/contracts/CampaignLib.sol";

contract CampaignVote is Initializable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /// @dev `Vote Events`
    event Voted(
        uint256 indexed voteId,
        uint256 indexed requestId,
        uint8 support
    );
    event VoteCancelled(
        uint256 indexed voteId,
        uint256 indexed requestId,
        uint8 support
    );

    /// @dev `Vote`
    struct Vote {
        uint8 support;
        uint256 requestId;
        bool voted;
        address approver;
    }
    Vote[] public votes;
    mapping(address => mapping(uint256 => uint256)) public voteId; // { user -> request -> vote }

    uint256 public campaignID;

    ICampaignFactory public campaignFactoryContract;
    ICampaign public campaignContract;

    modifier userIsVerified(address _user) {
        // call to external factory
        _;
    }

    function __CampaignVote_init(
        CampaignFactory _campaignFactory,
        Campaign _campaign,
        uint256 _campaignId
    ) public initializer {
        campaignFactoryContract = ICampaignFactory(address(_campaignFactory));
        campaignContract = ICampaign(address(_campaign));

        campaignID = _campaignId;
    }

    /**
     * @dev        Approvers only method which approves spending request issued by the campaign manager or factory
     * @param      _requestId   ID of request being voted on
     * @param      _support     An integer of 0 for against, 1 for in-favor, and 2 for abstain
     */
    function voteOnRequest(uint256 _requestId, uint8 _support)
        external
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(campaignContract.approvers(msg.sender), "non approver");
        require(!votes[voteId[msg.sender][_requestId]].voted, "voted");
        // require(
        //     block.timestamp <= requests[_requestId].duration,
        //     "request expired"
        // );

        // require(!requests[_requestId].void, "voided");

        // if (_support == 0) {
        //     requests[_requestId].againstCount = requests[_requestId]
        //         .againstCount
        //         .add(1);
        // } else if (_support == 1) {
        //     requests[_requestId].approvalCount = requests[_requestId]
        //         .approvalCount
        //         .add(1);
        // } else {
        //     requests[_requestId].abstainedCount = requests[_requestId]
        //         .abstainedCount
        //         .add(1);
        // }

        votes.push(Vote(_support, _requestId, true, msg.sender));
        voteId[msg.sender][_requestId] = votes.length.sub(1);

        emit Voted(votes.length.sub(1), _requestId, _support);
    }

    /**
     * @dev        Approvers only method which cancels initial vote on a request
     * @param      _requestId   ID of request being voted on
     */
    function cancelVote(uint256 _requestId)
        external
        userIsVerified(msg.sender)
        whenNotPaused
    {
        require(campaignContract.approvers(msg.sender), "non approver");

        require(votes[voteId[msg.sender][_requestId]].voted, "vote first");

        votes[voteId[msg.sender][_requestId]].voted = false;

        emit VoteCancelled(
            voteId[msg.sender][_requestId],
            _requestId,
            votes[voteId[msg.sender][_requestId]].support
        );
    }
}
