// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../CampaignFactory.sol";

contract CampaignVote is Initializable {
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
    Vote[] votes;
    mapping(address => mapping(uint256 => uint256)) voteId; // { user -> request -> vote }

    function __CampaignVote_init(
        CampaignFactory _factory,
        Campaign _campaign
    ) public initializer {

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
        require(approvers[msg.sender], "non approver");
        require(
            block.timestamp <= requests[_requestId].duration,
            "request expired"
        );
        require(votes[voteId[msg.sender][_requestId]].voted, "vote first");

        votes[voteId[msg.sender][_requestId]].voted = false;

        if (votes[voteId[msg.sender][_requestId]].support == 0) {
            requests[_requestId].againstCount = requests[_requestId]
                .againstCount
                .sub(1);
        } else if (votes[voteId[msg.sender][_requestId]].support == 1) {
            requests[_requestId].approvalCount = requests[_requestId]
                .approvalCount
                .sub(1);
        } else {
            requests[_requestId].abstainedCount = requests[_requestId]
                .abstainedCount
                .sub(1);
        }

        emit VoteCancelled(
            voteId[msg.sender][_requestId],
            _requestId,
            votes[voteId[msg.sender][_requestId]].support
        );
    }
}