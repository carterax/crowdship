// contracts/Roles.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract Roles {
    bytes32 public constant MANAGER = keccak256("MANAGER");

    // campaign roles
    bytes32 public constant SET_CAMPAIGN_SETTINGS =
        keccak256("SET_CAMPAIGN_SETTINGS");
    bytes32 public constant EXTEND_DEADLINE = keccak256("EXTEND_DEADLINE");
    bytes32 public constant CONTRIBUTOR_APPROVAL =
        keccak256("CONTRIBUTOR_APPROVAL");
    bytes32 public constant FINALIZE_REQUEST = keccak256("FINALIZE_REQUEST");
    bytes32 public constant REVIEW_MODE = keccak256("REVIEW_MODE");
    bytes32 public constant MARK_CAMPAIGN_COMPLETE =
        keccak256("MARK_CAMPAIGN_COMPLETE");
    bytes32 public constant CREATE_REQUEST = keccak256("CREATE_REQUEST");
    bytes32 public constant VOID_REQUEST = keccak256("VOID_REQUEST");
    bytes32 public constant CREATE_REWARD = keccak256("CREATE_REWARD");
    bytes32 public constant MODIFY_REWARD = keccak256("MODIFY_REWARD");
    bytes32 public constant DESTROY_REWARD = keccak256("DESTROY_REWARD");
}
