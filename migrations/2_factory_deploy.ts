export {};
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Factory = artifacts.require('Factory');

module.exports = async function (deployer) {
  await deployProxy(Factory, { deployer });
};
