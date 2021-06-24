// test/factory.test.js
const { expect } = require('chai');
const { internet } = require('faker');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');

const userTests = require('./resources/users.test');
const categoryTests = require('./resources/categories.test');
const campaignTests = require('./resources/campaigns.test');

// Start test block
contract('CampaignFactory', function ([owner, addr1, addr2, addr3, addr4]) {
  beforeEach(async function () {
    this.factory = await Factory.new();
    this.adminMail = internet.email();
    this.adminUserName = internet.userName();
    this.owner = owner;
    this.addr1 = addr1;
    this.addr2 = addr2;
    this.addr3 = addr3;
    this.addr4 = addr4;

    await this.factory.__CampaignFactory_init(
      this.owner,
      this.adminMail,
      this.adminUserName
    );

    // approve admin
    const adminId = await this.factory.userID(this.owner);
    await this.factory.toggleUserApproval(adminId, true);

    await this.factory.signUp(internet.email(), internet.userName(), {
      from: this.addr1,
    });

    await this.factory.signUp(internet.email(), internet.userName(), {
      from: this.addr2,
    });
  });

  it('deployer owns contract', async function () {
    expect(await this.factory.root()).to.equal(this.owner);
  });

  // user resource
  userTests();

  // category resource
  categoryTests();

  // campaign resource
  campaignTests();
});
