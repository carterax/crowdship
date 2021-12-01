// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract ICampaignVote {
    struct Vote {
        uint8 support;
        uint256 requestId;
        bool voted;
        address approver;
    }
    mapping(address => mapping(uint256 => Vote)) public votes; // { user -> request -> vote }
}
