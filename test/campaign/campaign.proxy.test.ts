export {};
const { expect } = require('chai');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const { BN } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignRewards = artifacts.require('CampaignRewards');

contract('Campaign (proxy)', function ([campaignOwner]) {
  beforeEach(async function () {
    this.campaignFactory = await Factory.new();
    this.campaignRewards = await CampaignRewards.new();

    this.campaign = await deployProxy(
      Campaign,
      [
        this.campaignFactory.address,
        this.campaignRewards.address,
        campaignOwner,
        0,
      ],
      {
        initializer: '__Campaign_init',
      }
    );
  });

  it('campaignOwner should be initialized', async function () {
    expect(await this.campaign.root()).to.equal(campaignOwner);
  });

  it('campaign state should be genesis', async function () {
    expect((await this.campaign.campaignState()).toString()).to.be.equal('0');
  });

  it('campaign ID should be initialized', async function () {
    expect(await this.campaign.campaignID()).to.be.bignumber.equal(new BN('0'));
  });

  it('campaign should be paused', async function () {
    expect(await this.campaign.paused()).to.be.equal(true);
  });

  it('should initialize default roles', async function () {
    const DEFAULT_ADMIN_ROLE = await this.campaign.DEFAULT_ADMIN_ROLE();

    expect(
      await this.campaign.hasRole(DEFAULT_ADMIN_ROLE, campaignOwner)
    ).to.equal(true);
  });
});
