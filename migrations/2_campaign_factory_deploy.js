// migrations/2_deploy_upgradeable_campaign_factory.js
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');

module.exports = async function (deployer) {
  await deployProxy(
    CampaignFactory,
    ['0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1', 'test@test.com', 'booga'],
    { deployer, initializer: '__CampaignFactory_init' }
  );
};
