// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./CampaignFactory.sol";

contract Factory {
  using SafeMathUpgradeable for uint256;

  event CampaignFactoryDeployed(address indexed campaignFactory, address factoryWallet, address owner, uint256 campaignIndex);

  struct DeployedCampaignFactory {
    address factory;
  }
  mapping(address => DeployedCampaignFactory) public deployedCampaigns;
  uint256 public deployedCampaignCount;

  function createCampaignFactory(address _campaignFactoryImplementation, address payable _wallet) public {
    address campaignFactory = ClonesUpgradeable.clone(_campaignFactoryImplementation);
    CampaignFactory(campaignFactory).__CampaignFactory_init(
        _wallet,
        msg.sender
    );
    deployedCampaigns[campaignFactory] = DeployedCampaignFactory({
      factory: campaignFactory
    });

    deployedCampaignCount = deployedCampaignCount.add(1);

    emit CampaignFactoryDeployed(campaignFactory, _wallet, msg.sender, deployedCampaignCount);
  }
}