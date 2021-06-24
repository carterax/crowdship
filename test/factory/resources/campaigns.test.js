const { expect } = require('chai');
const { lorem } = require('faker');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

module.exports = function () {
  it('can create campaign', async function () {
    await this.factory.createCategory('Sports', true);

    const receipt = await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph()
    );
    const campaign = await this.factory.deployedCampaigns(0);
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

    expect(
      (await this.factory.campaignCategories(0)).campaignCount
    ).to.be.bignumber.equal(new BN('1'));
    expect(
      await this.factory.getDeployedCampaignsCount()
    ).to.be.bignumber.equal(new BN('1'));
    expect(campaign.category).to.be.bignumber.equal(new BN('0'));
    expect(campaign.approved).to.equal(false);
    expect(campaign.featured).to.equal(false);
    expect(campaign.exists).to.equal(true);
    expect(campaign.createdAt).to.be.bignumber.equal(new BN(block.timestamp));
    expect(campaign.updatedAt).to.be.bignumber.equal(new BN('0'));
    expect(campaign.featureFor).to.be.bignumber.equal(new BN('0'));
    expect(campaign.active).to.equal(false);
    expect(await this.factory.campaignToOwner(campaign.campaign)).to.equal(
      this.owner
    );
    expect(
      await this.factory.campaignToID(campaign.campaign)
    ).to.be.bignumber.equal(new BN('0'));
    expectEvent(receipt, 'CampaignDeployed', {
      campaign: campaign.campaign,
    });
  });

  it('cannot create campaign if user is not verified', async function () {
    await this.factory.createCategory('Sports', true);
    await expectRevert.unspecified(
      this.factory.createCampaign(300, 0, lorem.sentence(), lorem.paragraph(), {
        from: this.addr1,
      })
    );
  });

  it('address without role cannot approve campaigns', async function () {
    await this.factory.createCategory('Sports', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph()
    );

    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, true, { from: this.addr1 })
    );
  });

  it('cannot approve campaign that does not exist', async function () {
    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, true)
    );
  });

  it('address with role can approve and unapprove campaigns', async function () {
    const MANAGE_CAMPAIGNS = await this.factory.MANAGE_CAMPAIGNS();

    await this.factory.createCategory('Sports', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph()
    );

    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, true, { from: this.addr1 })
    );

    await this.factory.addRole(this.addr1, MANAGE_CAMPAIGNS);

    await this.factory.toggleCampaignApproval(0, true, { from: this.addr1 });
    expect((await this.factory.deployedCampaigns(0)).approved).to.equal(true);

    await this.factory.toggleCampaignApproval(0, false, { from: this.addr1 });
    expect((await this.factory.deployedCampaigns(0)).approved).to.equal(false);
  });

  it('should modify campaign summary with correct role', async function () {
    let campaign,
      newTitle = lorem.sentence(),
      newPitch = lorem.paragraph();

    await this.factory.toggleUserApproval(1, true);
    await this.factory.createCategory('Technology', true);
    await this.factory.createCategory('Art', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph(),
      { from: this.addr1 }
    );

    const receipt = await this.factory.modifyCampaignSummary(
      0,
      1,
      newTitle,
      newPitch,
      true,
      {
        from: this.addr1,
      }
    );
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

    campaign = await this.factory.deployedCampaigns(0);

    expect(campaign.title).to.equal(newTitle);
    expect(campaign.pitch).to.equal(newPitch);
    expect(campaign.category).to.be.bignumber.equal(new BN('1'));
    expect(campaign.active).to.equal(true);
    expect(campaign.updatedAt).to.be.bignumber.equal(new BN(block.timestamp));
    expect(
      (await this.factory.campaignCategories(1)).campaignCount
    ).to.be.bignumber.equal(new BN('1'));
    expect(
      (await this.factory.campaignCategories(0)).campaignCount
    ).to.be.bignumber.equal(new BN('0'));
  });

  it('should not modify campaign summary with incorrect role', async function () {
    await this.factory.createCategory('Health', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph()
    );

    await expectRevert.unspecified(
      this.factory.modifyCampaignSummary(
        0,
        0,
        lorem.sentence(),
        lorem.paragraph(),
        true,
        { from: this.addr2 }
      )
    );
  });

  it('should not modify a campaign that does not exist', async function () {
    await expectRevert.unspecified(
      this.factory.modifyCampaignSummary(
        0,
        0,
        lorem.sentence(),
        lorem.paragraph(),
        true
      )
    );
  });

  it('should return total count of campaigns', async function () {
    await this.factory.createCategory('Fitness', true);
    await this.factory.createCategory('Cooking', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph()
    );
    await this.factory.createCampaign(
      300,
      1,
      lorem.sentence(),
      lorem.paragraph()
    );

    expect(
      await this.factory.getDeployedCampaignsCount()
    ).to.be.bignumber.equal(new BN('2'));
  });

  it('should return total amount of campaigns', async function () {
    await this.factory.createCategory('Fitness', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph()
    );
    await this.factory.createCampaign(
      500,
      0,
      lorem.sentence(),
      lorem.paragraph()
    );
    await this.factory.createCampaign(
      600,
      0,
      lorem.sentence(),
      lorem.paragraph()
    );

    expect(
      await this.factory.getDeployedCampaignsCount()
    ).to.be.bignumber.equal(new BN('3'));
  });

  it('should delete campaign with right role', async function () {
    const campaignID = 0,
      catID = 0;

    await this.factory.createCategory('Gaming', true);
    await this.factory.createCampaign(
      300,
      catID,
      lorem.sentence(),
      lorem.paragraph()
    );

    const receipt = await this.factory.destroyCampaign(campaignID);
    const campaign = await this.factory.deployedCampaigns(campaignID);

    expect(campaign.exists).to.equal(false);
    expectEvent(receipt, 'CampaignDestroyed', { id: new BN(campaignID) });
  });

  it('cannot delete campaign without role', async function () {
    const catID = 0,
      campaignID = 0,
      userId = await this.factory.userID(this.addr1);

    await this.factory.createCategory('Gaming', true);
    await this.factory.toggleUserApproval(userId, true);
    await this.factory.createCampaign(
      300,
      catID,
      lorem.sentence(),
      lorem.paragraph(),
      { from: this.addr1 }
    );

    await expectRevert.unspecified(
      this.factory.destroyCampaign(campaignID, { from: this.addr2 })
    );

    const campaign = await this.factory.deployedCampaigns(campaignID);

    expect(campaign.exists).to.equal(true);
  });

  // TODO: test toggleCampaignFeatured
};
