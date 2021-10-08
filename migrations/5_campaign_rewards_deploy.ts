export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignRewards = artifacts.require('CampaignRewards');

module.exports = async function (deployer) {
  const factory = await CampaignFactory.new();
  const campaignImplementation = await Campaign.new();

  await deployProxy(
    CampaignRewards,
    [
      factory.address,
      campaignImplementation.address,
      '0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e',
      0,
    ],
    {
      deployer,
      initializer: '__CampaignRewards_init',
    }
  );
};
