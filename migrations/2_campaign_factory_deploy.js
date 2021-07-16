// migrations/2_deploy_upgradeable_campaign_factory.js
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const TestToken = artifacts.require('TestToken');

module.exports = async function(deployer) {
  const factory = await deployProxy(
    CampaignFactory,
    ['0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1'],
    { deployer, initializer: '__CampaignFactory_init' }
  );

  await deployProxy(TestToken, ['Test Token', 'TT'], {
    deployer,
    initializer: '__TestToken_init',
  });

  await deployProxy(
    Campaign,
    [factory.address, '0x1dF62f291b2E969fB0849d99D9Ce41e2F137006e'],
    {
      deployer,
      initializer: '__Campaign_init',
    }
  );
};
