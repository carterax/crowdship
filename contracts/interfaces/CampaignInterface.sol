// contracts/interfaces/CampaignInterface.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract CampaignInterface {
    address public root;
    uint256 public campaignID;

    mapping(address => bool) public approvers;
}
