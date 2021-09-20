export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignRewards = artifacts.require('CampaignRewards');

module.exports = async function (deployer, network) {
  const campaignImplementation = await Campaign.new();
  const campaignRewardsImplementation = await CampaignRewards.new();
  const ganacheAccount = '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1';
  const gnosisAccount = '0x6b9238Ca0a223b6Ac6DFB2BFbC1bC80E013D94eF';

  await deployProxy(
    CampaignFactory,
    [
      network === 'development' ? ganacheAccount : gnosisAccount,
      campaignImplementation.address,
      campaignRewardsImplementation.address,
    ],
    { deployer, initializer: '__CampaignFactory_init' }
  );
};
