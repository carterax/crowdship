export {};
const { admin } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer, network) {
  // Use address of your Gnosis Safe
  const gnosisSafe = '0xD2e89Fc002E6B1dDe30C0123665ecC7a6be3C1f0';

  // Don't change ProxyAdmin ownership for our test network
  if (network !== 'development') {
    // The owner of the ProxyAdmin can upgrade our contracts
    await admin.transferProxyAdminOwnership(gnosisSafe);
  }
};
