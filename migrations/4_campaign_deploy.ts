export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignReward = artifacts.require('CampaignReward');
const CampaignRequest = artifacts.require('CampaignRequest');
const CampaignVote = artifacts.require('CampaignVote');

module.exports = async function (deployer) {
  const factory = await CampaignFactory.new();
  const campaignRewardsImplementation = await CampaignReward.new();
  const campaignRequestImplementation = await CampaignRequest.new();
  const campaignVoteImplementation = await CampaignVote.new();

  await deployProxy(
    Campaign,
    [
      factory.address,
      campaignRewardsImplementation.address,
      campaignRequestImplementation.address,
      campaignVoteImplementation.address,
      '0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e',
    ],
    {
      deployer,
      initializer: '__Campaign_init',
    }
  );
};
