// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title TestToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 */
contract TestToken is Initializable, ContextUpgradeable, ERC20Upgradeable {
    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    function __TestToken_init(string memory name, string memory symbol)
        public
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        _mint(_msgSender(), 10000 * (10**uint256(decimals())));
    }
}
