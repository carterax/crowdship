// test/Box.test.js
// Load dependencies
const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');

// Start test block
contract('CampaignFactory', function ([owner, addr1, addr2]) {
  beforeEach(async function () {
    this.factory = await Factory.new();
    await this.factory.__CampaignFactory_init(owner);
  });

  it('deployer owns contract', async function () {
    expect(await this.factory.root()).to.equal(owner);
  });

  it('deployer can create category', async function () {
    await this.factory.createCategory('Technology', true);
    await this.factory.createCategory('Health', true);

    expect((await this.factory.getCategories()).length).to.equal(2);
    expect(await this.factory.categoryIsTaken('Technology')).to.equal(true);
    expect(await this.factory.categoryIsTaken('Health')).to.equal(true);
  });

  it('non managers cannot create category', async function () {
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true, { from: addr1 })
    );
  });

  it('address with role can create category', async function () {
    const MANAGE_ANALYTICS = await this.factory.MANAGE_ANALYTICS();
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();

    await this.factory.addRole(addr1, MANAGE_ANALYTICS);
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true, { from: addr1 })
    );

    await this.factory.addRole(addr1, MANAGE_CATEGORIES);
    await this.factory.createCategory('Sports', false, { from: addr1 });

    expect((await this.factory.getCategories()).length).to.equal(1);
    expect(await this.factory.categoryIsTaken('Technology')).to.equal(false);
    expect(await this.factory.categoryIsTaken('Sports')).to.equal(true);
  });

  it('category name must be unique', async function () {
    await this.factory.createCategory('Technology', true);
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true)
    );
  });

  it('cannot delete a category that does not exist', async function () {
    expect(await this.factory.categoryIsTaken('Technology')).to.equal(false);
    await expectRevert.unspecified(this.factory.destroyCategory(0));
  });

  it('cannot delete categories without role', async function () {
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();

    await this.factory.createCategory('Gaming', false);
    await expectRevert.unspecified(
      this.factory.destroyCategory(0, { from: addr1 })
    );

    await this.factory.addRole(addr1, MANAGE_CATEGORIES);
    await this.factory.destroyCategory(0, { from: addr1 });

    const category = await this.factory.campaignCategories(0);

    expect(category.exists).to.equal(false);
    expect(await this.factory.categoryIsTaken(category.title)).to.equal(false);
  });

  it('can return all categories', async function () {
    await this.factory.createCategory('Cooking', true);
    await this.factory.createCategory('Health', false);
    await this.factory.createCategory('Technology', false);

    expect((await this.factory.getCategories()).length).to.equal(3);
  });

  it('can return categories count', async function () {
    await this.factory.createCategory('Cooking', true);
    await this.factory.createCategory('Health', false);
    await this.factory.createCategory('Technology', false);

    expect(await this.factory.getCategoriesCount()).to.be.bignumber.equal(
      new BN('3')
    );
  });

  it("cannot create campaign if category isn't active and does not exist", async function () {
    await expectRevert.unspecified(this.factory.createCampaign(300, 0)); // cat does not exist

    await this.factory.createCategory('Sports', false);
    await expectRevert.unspecified(this.factory.createCampaign(1200, 0)); // cat not active
  });

  it('can create campaign', async function () {
    await this.factory.createCategory('Sports', true);

    const receipt = await this.factory.createCampaign(300, 0, { from: addr1 });
    const campaigns = await this.factory.getDeployedCampaigns();

    expect(campaigns.length).to.equal(1);
    expect(campaigns[0].approved).to.equal(false);
    expect(campaigns[0].featured).to.equal(false);
    expect(campaigns[0].active).to.equal(false);
    expect(await this.factory.campaignToOwner(campaigns[0].campaign)).to.equal(
      addr1
    );
    expect(
      await this.factory.campaignToID(campaigns[0].campaign)
    ).to.be.bignumber.equal(new BN('0'));
    expectEvent(receipt, 'CampaignDeployed', {
      campaign: campaigns[0].campaign,
    });
  });

  it('address without role cannot approve campaigns', async function () {
    await this.factory.createCategory('Sports', true);
    await this.factory.createCampaign(300, 0);

    let campaigns = await this.factory.getDeployedCampaigns();

    await expectRevert.unspecified(
      this.factory.approveCampaign(0, { from: addr1 })
    );
  });

  it('cannot approve campaign that does not exist', async function () {
    await expectRevert.unspecified(this.factory.approveCampaign(0));
  });

  it('address with role can approve campaigns', async function () {
    const MANAGE_CAMPAIGNS = await this.factory.MANAGE_CAMPAIGNS();

    await this.factory.createCategory('Sports', true);
    await this.factory.createCampaign(300, 0);

    let campaigns = await this.factory.getDeployedCampaigns();

    await expectRevert.unspecified(
      this.factory.approveCampaign(0, { from: addr1 })
    );

    await this.factory.addRole(addr1, MANAGE_CAMPAIGNS);
    await this.factory.approveCampaign(0, { from: addr1 });

    campaigns = await this.factory.getDeployedCampaigns();

    expect(campaigns[0].approved).to.equal(true);
  });

  it('cannot delete campaign without role', async function () {
    const MANAGE_CAMPAIGNS = await this.factory.MANAGE_CAMPAIGNS();
    const campaignID = 0;
    const catID = 0;

    await this.factory.createCategory('Gaming', true);
    await this.factory.createCampaign(300, catID, { from: addr1 });

    await expectRevert.unspecified(
      this.factory.destroyCampaign(campaignID, { from: addr2 })
    );

    await this.factory.addRole(addr2, MANAGE_CAMPAIGNS);

    const receipt = await this.factory.destroyCampaign(campaignID, {
      from: addr2,
    });
    const campaigns = await this.factory.getDeployedCampaigns();

    expect(campaigns[campaignID].exists).to.equal(false);
    expectEvent(receipt, 'CampaignDestroyed', { id: new BN(campaignID) });
  });

  it('can toggle campaign state', async function () {
    let campaign;

    await this.factory.createCategory('Health', true);
    await this.factory.createCampaign(300, 0);

    await this.factory.toggleCampaignState(0, true);

    campaign = await this.factory.deployedCampaigns(0);

    expect(campaign.active).to.equal(true);

    await this.factory.toggleCampaignState(0, false);

    campaign = await this.factory.deployedCampaigns(0);

    expect(campaign.active).to.equal(false);
  });

  it('cannot toggle campaign state without role', async function () {
    await this.factory.createCategory('Fitness', true);
    await this.factory.createCampaign(300, 0);

    await expectRevert.unspecified(
      this.factory.toggleCampaignState(0, true, { from: addr1 })
    );
  });

  it('cannot toggle campaign state if it does not exist', async function () {
    expectRevert.unspecified(this.factory.toggleCampaignState(0, true));
  });

  // TODO: test toggleCampaignFeatured
  //it.todo('toggleCampaignFeatured');
});
