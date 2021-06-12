// contracts/CampaignFactory.sol
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
    modifier onlyManager(bytes32 role) {
        require(hasRole(role, msg.sender));
        _;
    }
}
