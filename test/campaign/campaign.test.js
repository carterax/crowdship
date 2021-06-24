// test/campaign.test.js
const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');

contract('Campaign', function ([factoryOwner, campaignOwner, addr]) {
  // beforeEach(async function () {
  //   this.factory = await Factory.new();
  //   this.factory.__CampaignFactory_init(factoryOwner);
  //   this.campaign = await Campaign.new();
  // });
  // it('test', async function () {
  //   console.log(this.campaign.address);
  // });
});
