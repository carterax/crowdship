export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignReward = artifacts.require('CampaignReward');

module.exports = async function (deployer) {
  const campaignFactory = await CampaignFactory.new();
  const campaignImplementation = await Campaign.new();

  await deployProxy(
    CampaignReward,
    [campaignFactory.address, campaignImplementation.address, 0],
    {
      deployer,
      initializer: '__CampaignReward_init',
    }
  );
};
