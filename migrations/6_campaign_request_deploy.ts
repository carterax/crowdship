export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignRequest = artifacts.require('CampaignRequest');

module.exports = async function (deployer) {
  const campaignFactory = await CampaignFactory.new();
  const campaignImplementation = await Campaign.new();

  await deployProxy(
    CampaignRequest,
    [campaignFactory.address, campaignImplementation.address, 0],
    {
      deployer,
      initializer: '__CampaignRequest_init',
    }
  );
};
