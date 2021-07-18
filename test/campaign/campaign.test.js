// 2021-04-01
// test/campaign.test.js
const { expect, assert } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const TestToken = artifacts.require('TestToken');

contract('Campaign', function([
  campaignOwner,
  root,
  factoryWallet,
  addr1,
  addr2,
  addr3,
]) {
  beforeEach(async function() {
    this.root = root;
    this.campaignOwner = campaignOwner;
    this.factoryWallet = factoryWallet;
    this.addr1 = addr1;
    this.addr2 = addr2;
    this.addr3 = addr3;
    this.campaignImplementation = await Campaign.new();

    // test token setup
    this.testToken = await TestToken.new();
    await this.testToken.__TestToken_init('Test Token', 'TT', {
      from: this.root,
    });

    // factory setup
    this.factory = await Factory.new();
    await this.factory.__CampaignFactory_init(this.factoryWallet, {
      from: this.root,
    });
    await this.factory.setFactorySettings(
      factoryWallet,
      this.campaignImplementation.address,
      10,
      3,
      604800,
      86400,
      1000,
      10000,
      { from: this.root }
    );
    await this.factory.createCategory(true, { from: this.root });
    await this.factory.addToken(this.testToken.address, { from: this.root });
    await this.factory.toggleAcceptedToken(this.testToken.address, true, {
      from: this.root,
    });

    // campaign setup
    await this.factory.signUp({
      from: this.campaignOwner,
    });
    await this.factory.toggleUserApproval(1, true, { from: this.root });
    await this.factory.createCampaign(0, {
      from: this.campaignOwner,
    });
    const { campaign } = await this.factory.deployedCampaigns(0);
    this.campaignInstance = await Campaign.at(campaign);
  });

  it('deployer owns the campaign', async function() {
    assert.equal(await this.campaignInstance.root(), this.campaignOwner);
  });

  it('campaign is paused on initialization', async function() {
    assert.equal(await this.campaignInstance.paused(), true);
  });

  it('admin or campaign owner can set campaign minimum contribution and goals', async function() {});
});
