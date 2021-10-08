// contracts/CampaignLib.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../interfaces/CampaignInterface.sol";

library CampaignLib {
    /**
     * @dev        Returns if specified user is an approver
     * @param      _campaign    Campaign factory interface
     * @param      _user        Address of user check is being carried on
     */
    function isAnApprover(CampaignInterface _campaign, address _user)
        internal
        view
        returns (bool)
    {
        return _campaign.approvers(_user);
    }
}
