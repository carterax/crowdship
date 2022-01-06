// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./campaign/CampaignFactory.sol";

contract Factory {
    using SafeMathUpgradeable for uint256;

    event CampaignFactoryDeployed(
        address indexed campaignFactory,
        address governance,
        uint256 campaignIndex
    );

    struct DeployedCampaignFactory {
        address factory;
    }
    mapping(address => DeployedCampaignFactory) public deployedCampaigns;
    uint256 public deployedCampaignCount;

    function createCampaignFactory(
        address _campaignFactoryImplementation,
        address _governance,
        uint256[15] memory _config
    ) public {
        address campaignFactory = ClonesUpgradeable.clone(
            _campaignFactoryImplementation
        );
        CampaignFactory(campaignFactory).__CampaignFactory_init(
            _governance,
            _config
        );

        deployedCampaigns[campaignFactory] = DeployedCampaignFactory({
            factory: campaignFactory
        });

        deployedCampaignCount = deployedCampaignCount.add(1);

        emit CampaignFactoryDeployed(
            campaignFactory,
            _governance,
            deployedCampaignCount
        );
    }
}
