// contracts/AccessControl.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AccessControl is AccessControlUpgradeable {
    bytes32 public constant MANAGER = keccak256("MANAGER");

    // campaign roles
    bytes32 public constant SET_CAMPAIGN_SETTINGS =
        keccak256("SET_CAMPAIGN_SETTINGS");
    bytes32 public constant EXTEND_DEADLINE = keccak256("EXTEND_DEADLINE");
    bytes32 public constant CONTRIBUTOR_APPROVAL =
        keccak256("CONTRIBUTOR_APPROVAL");
    bytes32 public constant FINALIZE_REQUEST = keccak256("FINALIZE_REQUEST");
    bytes public constant REVIEW_MODE = keccak256("REVIEW_MODE");
    bytes public constant MARK_CAMPAIGN_COMPLETE =
        keccak256("MARK_CAMPAIGN_COMPLETE");

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _;
    }

    /// @dev Restricted to members of the manager role.
    modifier onlyManager() {
        require(hasRole(MANAGER, msg.sender));
        _;
    }

    /**
     * @dev        Add an account to the role. Restricted to admins.
     * @param      _account Address of user being assigned role
     * @param      _role   Role being assigned
     */
    function addRole(address _account, bytes32 _role)
        external
        virtual
        onlyAdmin
    {
        grantRole(_role, _account);
    }

    /**
     * @dev        Remove an account from the role. Restricted to admins.
     * @param      _account Address of user whose role is being removed
     * @param      _role   Role being removed
     */
    function removeRole(address _account, bytes32 _role)
        external
        virtual
        onlyAdmin
    {
        revokeRole(_role, _account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() external virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
