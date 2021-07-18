// test/factory.test.js
const { expect } = require('chai');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const TestToken = artifacts.require('TestToken');

const userTests = require('./resources/users.test');
const categoryTests = require('./resources/categories.test');
const campaignTests = require('./resources/campaigns.test');
const featurePackageTests = require('./resources/featurepackage.test');
const expectRevert = require('@openzeppelin/test-helpers/src/expectRevert');
const { BN } = require('@openzeppelin/test-helpers/src/setup');

// Start test block
contract('CampaignFactory', function([
  owner,
  factoryWallet,
  addr1,
  addr2,
  addr3,
  addr4,
  otherFactoryWallet,
]) {
  beforeEach(async function() {
    this.factory = await Factory.new();
    this.testToken = await TestToken.new();
    this.campaign = await Campaign.new();
    this.owner = owner;
    this.factoryWallet = factoryWallet;
    this.addr1 = addr1;
    this.addr2 = addr2;
    this.addr3 = addr3;
    this.addr4 = addr4;

    await this.factory.__CampaignFactory_init(this.factoryWallet, {
      from: this.owner,
    });

    await this.testToken.__TestToken_init('Test Token', 'TT', {
      from: this.owner,
    });

    // approve admin
    const adminId = await this.factory.userID(this.owner);
    await this.factory.toggleUserApproval(adminId, true);

    await this.factory.signUp({
      from: this.addr1,
    });

    await this.factory.signUp({
      from: this.addr2,
    });

    // add token
    await this.factory.addToken(this.testToken.address);

    // approve token
    await this.factory.toggleAcceptedToken(this.testToken.address, true);
  });

  /* -------------------------------------------------------------------------- */
  /*                          general factory settings                          */
  /* -------------------------------------------------------------------------- */
  it('should renounce oneself as admin', async function() {
    const DEFAULT_ADMIN_ROLE = await this.factory.DEFAULT_ADMIN_ROLE();
    await this.factory.renounceAdmin({ from: this.owner });
    expect(
      await this.factory.hasRole(DEFAULT_ADMIN_ROLE, this.owner)
    ).to.be.equal(false);
  });
  it('admin can remove role from non admin user', async function() {
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();
    await this.factory.addRole(this.addr2, MANAGE_CATEGORIES);
    await this.factory.removeRole(this.addr2, MANAGE_CATEGORIES);
    expect(
      await this.factory.hasRole(MANAGE_CATEGORIES, this.addr2)
    ).to.be.equal(false);
  });
  it('deployer owns contract', async function() {
    expect(await this.factory.root()).to.be.equal(this.owner);
  });
  // it('should change factory settings', async function() {
  //   await this.factory.setFactoryWallet(otherFactoryWallet);
  //   expect(await this.factory.factoryWallet()).to.be.equal(otherFactoryWallet);
  // });
  // it('should fail if non admin tries to change factory wallet', async function() {
  //   await expectRevert.unspecified(
  //     this.factory.setFactoryWallet(otherFactoryWallet, { from: this.addr1 })
  //   );
  // });
  // it('should set campaign implementation address', async function() {
  //   await this.factory.setCampaignImplementationAddress(this.campaign.address);
  //   expect(await this.factory.campaignImplementation()).to.be.equal(
  //     this.campaign.address
  //   );
  // });
  // it('should fail if non admin tries to set implementation address', async function() {
  //   await expectRevert.unspecified(
  //     this.factory.setCampaignImplementationAddress(this.campaign.address, {
  //       from: this.addr4,
  //     })
  //   );
  // });
  // it('should set default commission', async function() {
  //   await this.factory.setDefaultCommission(5);
  //   expect(await this.factory.defaultCommission()).to.be.bignumber.equal(
  //     new BN('5')
  //   );
  // });
  // it('should fail if non admin tries to set default commission', async function() {
  //   await expectRevert.unspecified(
  //     this.factory.setDefaultCommission(5, { from: this.addr3 })
  //   );
  // });
  it('should set commission per category', async function() {
    await this.factory.createCategory(true);
    await this.factory.createCategory(false);
    await this.factory.setCategoryCommission(0, 4);
    await this.factory.setCategoryCommission(1, 2);
    expect(await this.factory.categoryCommission(0)).to.be.bignumber.equal(
      new BN('4')
    );
    expect(await this.factory.categoryCommission(1)).to.be.bignumber.equal(
      new BN('2')
    );
  });
  it('set commission per category should fail if category does not exist', async function() {
    await expectRevert.unspecified(this.factory.setCategoryCommission(0, 4));
  });
  it('should fail if non admin tries to set commission per category', async function() {
    await this.factory.createCategory(true);
    await expectRevert.unspecified(
      this.factory.setCategoryCommission(0, 4, { from: this.addr2 })
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                                user resource                               */
  /* -------------------------------------------------------------------------- */
  userTests();

  /* -------------------------------------------------------------------------- */
  /*                              category resource                             */
  /* -------------------------------------------------------------------------- */
  categoryTests();

  /* -------------------------------------------------------------------------- */
  /*                              campaign resource                             */
  /* -------------------------------------------------------------------------- */
  campaignTests();

  /* -------------------------------------------------------------------------- */
  /*                          feature package resource                          */
  /* -------------------------------------------------------------------------- */
  featurePackageTests();
});
