// contracts/AccessControl.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AccessControl is AccessControlUpgradeable {
    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _;
    }

    /// @dev Restricted to members of the manager role.
    /// @param  role Role to be checked
    modifier onlyManager(bytes32 role) {
        require(hasRole(role, msg.sender));
        _;
    }

    /**
     * @dev        Add an account to the role. Restricted to admins.
     * @param      _account Address of user being assigned role
     * @param      _role   Role being assigned
     */
    function addRole(address _account, bytes32 _role) external virtual onlyAdmin {
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
