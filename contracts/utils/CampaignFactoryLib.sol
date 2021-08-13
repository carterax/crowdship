// contracts/CampaignFactoryLib.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./FactoryInterface.sol";

library CampaignFactoryLib {
    function canManageCampaigns(
        CampaignFactoryInterface _factory,
        address _user
    ) internal view returns (bool) {
        return _factory.canManageCampaigns(_user);
    }

    /**
     * @dev        Returns information on a campaign from the factory
     * @param      _factory     Campaign factory interface
     * @param      _prop        Transaction setting key
     */
    function getCampaignFactoryConfig(
        CampaignFactoryInterface _factory,
        string memory _prop
    ) internal view returns (uint256) {
        return _factory.campaignTransactionConfig(_prop);
    }

    /**
     * @dev        Returns information on a campaign from the factory
     * @param      _factory     Campaign factory interface
     * @param      _campaignId  ID of the campaign
     */
    function campaignInfo(
        CampaignFactoryInterface _factory,
        uint256 _campaignId
    )
        internal
        view
        returns (
            address,
            uint256,
            bool,
            bool
        )
    {
        bool campaignIsEnabled;
        bool campaignIsApproved;
        address campaignAddress;
        uint256 campaignCategory;

        (
            campaignAddress,
            ,
            ,
            ,
            campaignCategory,
            ,
            campaignIsEnabled,
            campaignIsApproved,

        ) = _factory.deployedCampaigns(_campaignId);

        return (
            campaignAddress,
            campaignCategory,
            campaignIsEnabled,
            campaignIsApproved
        );
    }

    /**
     * @dev        Returns information about a user from the factory
     * @param      _factory      Campaign factory interface
     * @param      _userAddress  Address of the user
     */
    function userInfo(CampaignFactoryInterface _factory, address _userAddress)
        internal
        view
        returns (address, bool)
    {
        require(address(_userAddress) != address(0));

        address userAddress;
        bool verified;

        (userAddress, , , verified, ) = _factory.users(
            _factory.userID(_userAddress)
        );

        return (userAddress, verified);
    }

    /**
     * @dev        Returns factory percentage cut on all requests per category
     * @param      _factory     Campaign factory interface
     * @param      _campaignId  ID of the campaign
     */
    function factoryPercentFee(
        CampaignFactoryInterface _factory,
        uint256 _campaignId
    ) internal returns (uint256) {
        uint256 campaignCategory;
        uint256 percentCommission;

        (, , , , campaignCategory, , , , ) = _factory.deployedCampaigns(
            _campaignId
        );
        percentCommission = _factory.categoryCommission(campaignCategory);

        if (percentCommission == 0) {
            percentCommission = _factory.getCampaignTransactionConfig(
                "defaultCommission"
            );
        }

        return percentCommission;
    }
}
