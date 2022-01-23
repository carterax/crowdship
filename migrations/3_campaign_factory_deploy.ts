export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CampaignFactory = artifacts.require('CampaignFactory');

module.exports = async function (deployer, network) {
  const ganacheAccount = '0x6b9238Ca0a223b6Ac6DFB2BFbC1bC80E013D94eF';
  const gnosisAccount = '0xD2e89Fc002E6B1dDe30C0123665ecC7a6be3C1f0';

  await deployProxy(
    CampaignFactory,
    [
      network === 'development' ? ganacheAccount : gnosisAccount,
      '0x6b9238Ca0a223b6Ac6DFB2BFbC1bC80E013D94eF',
      '0x6b9238Ca0a223b6Ac6DFB2BFbC1bC80E013D94eF',
      '0x6b9238Ca0a223b6Ac6DFB2BFbC1bC80E013D94eF',
      '0x6b9238Ca0a223b6Ac6DFB2BFbC1bC80E013D94eF',
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    { deployer, initializer: '__CampaignFactory_init' }
  );
};
