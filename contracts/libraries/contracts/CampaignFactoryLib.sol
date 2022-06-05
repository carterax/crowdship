// contracts/CampaignFactoryLib.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../campaign/Campaign.sol";
import "../../interfaces/ICampaignFactory.sol";

library CampaignFactoryLib {
    /**
     * @dev        Returns if caller can manage campaigns
     * @param      _factory     Campaign factory interface
     * @param      _user        Address of caller
     */
    function canManageCampaigns(ICampaignFactory _factory, address _user)
        internal
        view
        returns (bool)
    {
        return _factory.canManageCampaigns(_user);
    }

    /**
     * @dev        Returns information on a campaign from the factory
     * @param      _factory     Campaign factory interface
     * @param      _prop        Transaction config key
     */
    function getCampaignFactoryConfig(
        ICampaignFactory _factory,
        string memory _prop
    ) internal view returns (uint256) {
        return _factory.campaignTransactionConfig(_prop);
    }

    /**
     * @dev        Returns information on a campaign from the factory
     * @param      _factory     Campaign factory interface
     * @param      _campaign    Address of the campaign
     */
    function campaignInfo(ICampaignFactory _factory, Campaign _campaign)
        internal
        view
        returns (uint256, bool)
    {
        uint256 campaignCategory;
        bool privateCampaign;

        (, , , campaignCategory, , , privateCampaign) = _factory.campaigns(
            _campaign
        );

        return (campaignCategory, privateCampaign);
    }

    /**
     * @dev        Returns information about a user from the factory
     * @param      _factory      Campaign factory interface
     * @param      _userAddress  Address of the user
     */
    function userInfo(ICampaignFactory _factory, address _userAddress)
        internal
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        require(address(_userAddress) != address(0));

        uint256 joined;
        uint256 updatedAt;
        bool verified;

        (joined, updatedAt, , verified) = _factory.users(_userAddress);

        return (joined, updatedAt, verified);
    }

    /**
     * @dev        Sends fee after request finalization to factory
     * @param      _factory     Campaign factory interface
     * @param      _campaign    Address of campaign sending fee
     * @param      _amount      Amount being sent
     */
    function sendCommissionFee(
        ICampaignFactory _factory,
        Campaign _campaign,
        uint256 _amount
    ) internal {
        _factory.receiveCampaignCommission(_campaign, _amount);
    }

    /**
     * @dev        Returns factory percentage cut on all requests per category
     * @param      _factory     Campaign factory interface
     * @param      _campaign    Address of the campaign
     */
    function factoryPercentFee(ICampaignFactory _factory, Campaign _campaign)
        internal
        view
        returns (uint256)
    {
        uint256 campaignCategory;
        uint256 percentCommission;

        (, , , campaignCategory, , , ) = _factory.campaigns(_campaign);
        percentCommission = _factory.categoryCommission(campaignCategory);

        if (percentCommission == 0) {
            percentCommission = _factory.campaignTransactionConfig(
                "defaultCommission"
            );
        }

        return percentCommission;
    }
}
