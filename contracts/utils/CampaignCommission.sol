// contracts/AccessControl.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./FactoryInterface.sol";

library CampaignCommission {
    /**
     * @dev        Returns factory percentage cut on all requests per category
     * @param      _factory   Campaign factory interface
     * @param      _campaignId  ID of the campaign
     */
    function factoryPercentFee(
        CampaignFactoryInterface _factory,
        uint256 _campaignId
    ) internal view returns (uint256) {
        uint256 campaignCategory;
        uint256 percentCommission;

        (, campaignCategory, , ) = _factory.deployedCampaigns(_campaignId);
        percentCommission = _factory.categoryCommission(campaignCategory);

        if (percentCommission == 0) {
            percentCommission = _factory.defaultCommission();
        }

        return percentCommission;
    }
}
