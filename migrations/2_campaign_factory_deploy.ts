export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');

module.exports = async function (deployer, network) {
  const ganacheAccount = '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1';
  const gnosisAccount = '0x6b9238Ca0a223b6Ac6DFB2BFbC1bC80E013D94eF';

  await deployProxy(
    CampaignFactory,
    [network === 'development' ? ganacheAccount : gnosisAccount],
    { deployer, initializer: '__CampaignFactory_init' }
  );
};
