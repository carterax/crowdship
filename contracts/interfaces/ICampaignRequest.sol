// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract ICampaignRequest {
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

    function signRequestFinalization(uint256 _requestId) external virtual;

    function signRequestVote(uint256 _requestId, uint256 _support)
        external
        virtual;

    function cancelVoteSignature(uint256 _requestId) external virtual;
}
