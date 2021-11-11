// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../CampaignFactory.sol';
import './Campaign.sol';

contract CampaignRequest {
  /// @dev `Request Events`
  event RequestAdded(
    uint256 indexed requestId,
    uint256 duration,
    uint256 value,
    address recipient
  );
  event RequestVoided(uint256 indexed requestId);
  event RequestComplete(uint256 indexed requestId);

  /// @dev `Request`
  struct Request {
    address payable recipient;
    bool complete;
    uint256 value;
    uint256 approvalCount;
    uint256 againstCount;
    uint256 abstainedCount;
    uint256 duration;
    bool void;
  }

  uint256 public requestCount;

  Request[] public requests;

  uint256 public finalizedRequestCount;
  uint256 public currentRunningRequest;

  function __CampaignRequest_init(
    CampaignFactory _factory,
    Campaign _campaign
  ) public initializer {}

  /**
     * @dev        Creates a formal request to withdraw funds from user contributions called by the campagn manager or factory
                   Restricted unless target is met and deadline is expired
     * @param      _recipient   Address where requested funds are deposited
     * @param      _value       Amount being requested by the campaign manager
     * @param      _duration    Duration until users aren't able to vote on the request
     */
  function createRequest(address payable _recipient,
    uint256 _value,
    uint256 _duration
  ) external onlyAdmin whenNotPaused {
    require(address(_recipient) != address(0));

    if (totalCampaignContribution < target)
      require(block.timestamp >= deadline, 'deadline not expired');

    if (goalType == GOALTYPE.FIXED) {
      require(
        totalCampaignContribution >= target &&
          campaignState == CAMPAIGN_STATE.LIVE,
        'target unmet'
      );
    }
    require(
      _value >=
        CampaignFactoryLib.getCampaignFactoryConfig(
          campaignFactoryContract,
          'minimumRequestAmountAllowed'
        ) &&
        _value <=
        CampaignFactoryLib.getCampaignFactoryConfig(
          campaignFactoryContract,
          'maximumRequestAmountAllowed'
        ),
      'amount deficit'
    );
    require(_value <= campaignBalance, 'amount over balance');
    require(
      _duration >=
        CampaignFactoryLib.getCampaignFactoryConfig(
          campaignFactoryContract,
          'minRequestDuration'
        ) &&
        _duration <=
        CampaignFactoryLib.getCampaignFactoryConfig(
          campaignFactoryContract,
          'maxRequestDuration'
        ),
      'duration deficit'
    );

    // before creating a new request last request should be complete
    // applies if there's a request before
    if (requestCount >= 1)
      require(requests[currentRunningRequest].complete, 'request ongoing');

    requests.push(
      Request(
        _recipient,
        false,
        _value,
        0,
        0,
        0,
        block.timestamp.add(_duration),
        false
      )
    );
    requestCount = requestCount.add(1);
    currentRunningRequest = requests.length.sub(1);

    emit RequestAdded(requests.length.sub(1), _duration, _value, _recipient);
  }

  /**
   * @dev        Renders a request void and useless
   * @param      _requestId   ID of request being voided
   */
  function voidRequest(uint256 _requestId) external onlyAdmin whenNotPaused {
    // request must not be void
    // request must have no votes
    // request should not have been finalized
    require(!requests[_requestId].void, 'voided');
    require(requests[_requestId].approvalCount < 1, 'has approvals');
    // require(!requests[_requestId].complete, "already finalized");

    requests[_requestId].void = true;

    emit RequestVoided(_requestId);
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
    require(approvers[msg.sender], 'non approver');
    require(!votes[voteId[msg.sender][_requestId]].voted, 'voted');
    require(
      block.timestamp <= requests[_requestId].duration,
      'request expired'
    );

    require(!requests[_requestId].void, 'voided');

    if (_support == 0) {
      requests[_requestId].againstCount = requests[_requestId].againstCount.add(
        1
      );
    } else if (_support == 1) {
      requests[_requestId].approvalCount = requests[_requestId]
        .approvalCount
        .add(1);
    } else {
      requests[_requestId].abstainedCount = requests[_requestId]
        .abstainedCount
        .add(1);
    }

    votes.push(Vote(_support, _requestId, true, msg.sender));
    voteId[msg.sender][_requestId] = votes.length.sub(1);

    emit Voted(votes.length.sub(1), _requestId, _support);
  }

  /**
   * @dev        Withdrawal method called only when a request receives the right amount votes
   * @param      _requestId      ID of request being withdrawn
   */
  function finalizeRequest(uint256 _requestId)
    external
    onlyAdmin
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
    require(
      percentOfRequestApprovals.value >=
        CampaignFactoryLib
          .getCampaignFactoryConfig(
            campaignFactoryContract,
            'requestFinalizationThreshold'
          )
          .mul(DecimalMath.UNIT),
      'approval deficit'
    );
    require(!request.complete, 'finalized');

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

    CampaignFactoryLib.sendCommissionFee(
      campaignFactoryContract,
      address(this),
      factoryFee.value
    );

    for (uint256 i = 0; i < addresses.length; i++) {
      SafeERC20Upgradeable.safeTransfer(
        IERC20Upgradeable(acceptedToken),
        addresses[i],
        payouts[i]
      );
    }

    emit RequestComplete(_requestId);
  }
}
