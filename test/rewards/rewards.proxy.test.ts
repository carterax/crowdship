export {};
const { expect } = require('chai');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const { BN } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignRewards = artifacts.require('CampaignRewards');

contract('Campaign Rewards (proxy)', function ([campaignOwner]) {
  beforeEach(async function () {
    this.campaignFactory = await Factory.new();
    this.campaign = await Campaign.new();

    this.campaignRewards = await deployProxy(
      CampaignRewards,
      [this.campaignFactory.address, this.campaign.address, campaignOwner, 0],
      {
        initializer: '__CampaignRewards_init',
      }
    );
  });

  it('campaignOwner should be initialized', async function () {
    expect(await this.campaignRewards.root()).to.equal(campaignOwner);
  });

  it('campaign ID should be initialized', async function () {
    expect(await this.campaignRewards.campaignID()).to.be.bignumber.equal(
      new BN('0')
    );
  });

  it('should initialize default roles', async function () {
    const DEFAULT_ADMIN_ROLE = await this.campaignRewards.DEFAULT_ADMIN_ROLE();

    expect(
      await this.campaignRewards.hasRole(DEFAULT_ADMIN_ROLE, campaignOwner)
    ).to.equal(true);
  });
});
