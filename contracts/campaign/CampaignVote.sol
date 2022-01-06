// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./CampaignFactory.sol";
import "./Campaign.sol";

import "../interfaces/ICampaignFactory.sol";
import "../interfaces/ICampaign.sol";
import "../interfaces/ICampaignRequest.sol";

import "../libraries/contracts/CampaignFactoryLib.sol";
import "../libraries/contracts/CampaignLib.sol";

contract CampaignVote is Initializable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /// @dev `Vote Events`
    event Voted(
        uint256 indexed voteId,
        uint256 indexed requestId,
        uint8 support,
        string hashedVote
    );
    event VoteCancelled(
        uint256 indexed voteId,
        uint256 indexed requestId,
        uint8 support
    );

    /// @dev `Vote`
    struct Vote {
        uint256 id;
        uint8 support;
        uint256 requestId;
        string hashedVote;
        bool voted;
        address approver;
    }
    mapping(address => mapping(uint256 => Vote)) public votes; // { user -> request -> vote }
    uint256 public voteCount;

    ICampaignFactory public campaignFactoryInterface;
    ICampaign public campaignInterface;

    /// @dev Ensures a user is verified
    modifier userIsVerified(address _user) {
        bool verified;
        (, , verified) = CampaignFactoryLib.userInfo(
            campaignFactoryInterface,
            _user
        );
        require(verified, "user not verified");
        _;
    }

    /**
     * @dev        Constructor
     * @param      _campaignFactory     Address of factory
     * @param      _campaign            Address of campaign contract this contract belongs to
     */
    function __CampaignVote_init(
        CampaignFactory _campaignFactory,
        Campaign _campaign
    ) public initializer {
        campaignFactoryInterface = ICampaignFactory(address(_campaignFactory));
        campaignInterface = ICampaign(address(_campaign));
    }

    /**
     * @dev        Approvers only method which approves spending request issued by the campaign manager
     * @param      _requestId   ID of request being voted on
     * @param      _support     An integer of 0 for against, 1 for in-favor, and 2 for abstain
     */
    function voteOnRequest(
        uint256 _requestId,
        uint8 _support,
        string memory _hashedVote
    ) external userIsVerified(msg.sender) whenNotPaused {
        require(campaignInterface.approvers(msg.sender), "non approver");
        require(!votes[msg.sender][_requestId].voted, "voted");

        voteCount = voteCount.add(1);
        votes[msg.sender][_requestId] = Vote(
            voteCount.sub(1),
            _support,
            _requestId,
            _hashedVote,
            true,
            msg.sender
        );

        ICampaignRequest(campaignInterface.campaignRequestContract())
            .signRequestVote(_requestId, _support);

        emit Voted(voteCount.sub(1), _requestId, _support, _hashedVote);
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
        require(campaignInterface.approvers(msg.sender), "non approver");

        require(votes[msg.sender][_requestId].voted, "vote first");

        votes[msg.sender][_requestId].voted = false;

        ICampaignRequest(campaignInterface.campaignRequestContract())
            .cancelVoteSignature(_requestId);

        emit VoteCancelled(
            votes[msg.sender][_requestId].id,
            _requestId,
            votes[msg.sender][_requestId].support
        );
    }
}
