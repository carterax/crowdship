export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignVote = artifacts.require('CampaignVote');

module.exports = async function (deployer) {
  const campaignFactory = await CampaignFactory.new();
  const campaignImplementation = await Campaign.new();

  await deployProxy(
    CampaignVote,
    [campaignFactory.address, campaignImplementation.address],
    {
      deployer,
      initializer: '__CampaignVote_init',
    }
  );
};
