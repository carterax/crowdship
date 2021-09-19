export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignRewards = artifacts.require('CampaignRewards');

module.exports = async function (deployer) {
  const campaignImplementation = await Campaign.new();
  const campaignRewardsImplementation = await CampaignRewards.new();

  await deployProxy(
    CampaignFactory,
    [
      '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1',
      campaignImplementation.address,
      campaignRewardsImplementation.address,
    ],
    { deployer, initializer: '__CampaignFactory_init' }
  );
};
