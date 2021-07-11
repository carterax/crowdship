const fs = require('fs');
const { expect } = require('chai');
const { lorem } = require('faker');
const {
  BN,
  expectEvent,
  expectRevert,
  constants,
} = require('@openzeppelin/test-helpers');

async function campaignSetup(factory, testToken) {
  await factory.createCategory('Sports', true);
  await factory.createCampaign(
    300,
    0,
    lorem.sentence(),
    lorem.paragraph(),
    testToken.address
  );
}

async function featureCampaignSetup(
  factory,
  testToken,
  time = 86400,
  {
    approveCampaign = true,
    activateCampaign = true,
    createFeaturePackage = true,
  } = {}
) {
  await factory.createCategory('Sport', true);
  await factory.createCampaign(
    300,
    0,
    lorem.sentence(),
    lorem.paragraph(),
    testToken.address
  );

  if (activateCampaign) await factory.toggleCampaignActive(0, true);
  if (approveCampaign) await factory.toggleCampaignApproval(0, true);
  if (createFeaturePackage)
    await factory.createFeaturePackage('Basic', 1000, time); // 24hr package

  await testToken.increaseAllowance(factory.address, 10000);
}

module.exports = function() {
  /* -------------------------------------------------------------------------- */
  /*                               createCampaign                               */
  /* -------------------------------------------------------------------------- */
  it('can create campaign', async function() {
    const minimum = 300,
      category = 0,
      title = lorem.sentence(),
      pitch = lorem.paragraph(),
      token = this.testToken.address;
    await this.factory.createCategory('Sports', true);
    const receipt = await this.factory.createCampaign(
      minimum,
      category,
      title,
      pitch,
      token
    );
    const campaign = await this.factory.deployedCampaigns(0);
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

    expect(
      (await this.factory.campaignCategories(0)).campaignCount
    ).to.be.bignumber.equal(new BN('1'));
    expect(await this.factory.campaignCount()).to.be.bignumber.equal(
      new BN('1')
    );
    expect(campaign.category).to.be.bignumber.equal(new BN('0'));
    expect(campaign.approved).to.equal(false);
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
      campaignId: new BN('0'),
      minimum: new BN(minimum),
      category: new BN(category),
      title,
      pitch,
      token,
    });
  });
  it("should not create campaign if category isn't active", async function() {
    await this.factory.createCategory('Music', false);
    await expectRevert.unspecified(
      this.factory.createCampaign(
        300,
        0,
        lorem.sentence(),
        lorem.paragraph(),
        this.testToken.address
      )
    );
  });
  it('should not create campaign if category does not exist', async function() {
    await expectRevert.unspecified(
      this.factory.createCampaign(
        300,
        0,
        lorem.sentence(),
        lorem.paragraph(),
        this.testToken.address
      )
    );
  });
  it('cannot create campaign if user is not verified', async function() {
    await this.factory.createCategory('Sports', true);
    await expectRevert.unspecified(
      this.factory.createCampaign(
        300,
        0,
        lorem.sentence(),
        lorem.paragraph(),
        this.testToken.address,
        {
          from: this.addr1,
        }
      )
    );
  });
  it('cannot create campaign with disapproved token', async function() {
    await this.factory.createCategory('Sports', true);
    await expectRevert.unspecified(
      this.factory.createCampaign(
        300,
        0,
        lorem.sentence(),
        lorem.paragraph(),
        constants.ZERO_ADDRESS
      )
    );
  });
  it('campaign creation should fail if factory is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(campaignSetup(this.factory, this.testToken));
  });
  it('campaign creation should work if factory is unpaused', async function() {
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await campaignSetup(this.factory, this.testToken);
    expect((await this.factory.deployedCampaigns(0)).exists).to.equal(true);
  });

  /* -------------------------------------------------------------------------- */
  /*                           toggleCampaignApproval                           */
  /* -------------------------------------------------------------------------- */
  it('address without role cannot approve campaigns', async function() {
    await this.factory.createCategory('Sports', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph(),
      this.testToken.address
    );
    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, true, { from: this.addr1 })
    );
  });
  it('cannot approve campaign that does not exist', async function() {
    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, true)
    );
  });
  it('address with role can approve and disapprove campaigns', async function() {
    const MANAGE_CAMPAIGNS = await this.factory.MANAGE_CAMPAIGNS();
    let approvalReceipt;
    await campaignSetup(this.factory, this.testToken);
    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, true, { from: this.addr1 })
    );
    await this.factory.addRole(this.addr1, MANAGE_CAMPAIGNS);
    approvalReceipt = await this.factory.toggleCampaignApproval(0, true, {
      from: this.addr1,
    });
    expect((await this.factory.deployedCampaigns(0)).approved).to.equal(true);
    expectEvent(approvalReceipt, 'CampaignApproval', {
      campaignId: new BN('0'),
      approval: true,
    });
    approvalReceipt = await this.factory.toggleCampaignApproval(0, false, {
      from: this.addr1,
    });
    expect((await this.factory.deployedCampaigns(0)).approved).to.equal(false);
    expectEvent(approvalReceipt, 'CampaignApproval', {
      campaignId: new BN('0'),
      approval: false,
    });
  });
  it('should not toggle campaign approval if factory is paused', async function() {
    await campaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, true)
    );
    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, false)
    );
  });
  it('should toggle campaign approval if factory is unpaused', async function() {
    await campaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.toggleCampaignApproval(0, true);
    expect((await this.factory.deployedCampaigns(0)).approved).to.be.equal(
      true
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                            toggleCampaignActive                            */
  /* -------------------------------------------------------------------------- */
  it('campaign owner can disable their campaigns', async function() {
    await campaignSetup(this.factory, this.testToken);
    const receipt = await this.factory.toggleCampaignActive(0, true);
    expect((await this.factory.deployedCampaigns(0)).active).to.equal(true);
    expectEvent(receipt, 'CampaignActiveToggle', {
      campaignId: new BN('0'),
      active: true,
    });
  });
  it('should not disable or enable a campaign that does not exist', async function() {
    await expectRevert.unspecified(this.factory.toggleCampaignActive(0, true));
  });
  it('cannot disable or enable a campaign without role', async function() {
    const userId = await this.factory.userID(this.addr1);
    await this.factory.toggleUserApproval(userId, true);
    await this.factory.createCategory('Sport', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph(),
      this.testToken.address,
      {
        from: this.addr1,
      }
    );
    await expectRevert.unspecified(
      this.factory.toggleCampaignApproval(0, true, { from: this.addr2 })
    );
  });
  it('should not enable or disable campaign if factory is paused', async function() {
    await campaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.toggleCampaignActive(0, true));
  });
  it('should enable or disable campaign if factory is unpaused', async function() {
    await campaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.toggleCampaignActive(0, true);
    expect((await this.factory.deployedCampaigns(0)).active).to.be.equal(true);
  });

  /* -------------------------------------------------------------------------- */
  /*                            modifyCampaignSummary                           */
  /* -------------------------------------------------------------------------- */
  it('should modify campaign summary with correct role', async function() {
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
      this.testToken.address,
      { from: this.addr1 }
    );
    const receipt = await this.factory.modifyCampaignSummary(
      0,
      1,
      newTitle,
      newPitch,
      {
        from: this.addr1,
      }
    );
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);
    campaign = await this.factory.deployedCampaigns(0);
    expect(campaign.title).to.equal(newTitle);
    expect(campaign.pitch).to.equal(newPitch);
    expect(campaign.category).to.be.bignumber.equal(new BN('1'));
    expect(campaign.updatedAt).to.be.bignumber.equal(new BN(block.timestamp));
    expect(
      (await this.factory.campaignCategories(1)).campaignCount
    ).to.be.bignumber.equal(new BN('1'));
    expect(
      (await this.factory.campaignCategories(0)).campaignCount
    ).to.be.bignumber.equal(new BN('0'));
    expectEvent(receipt, 'CampaignModified', {
      campaignId: new BN('0'),
      newCategory: new BN('1'),
      newTitle: newTitle,
      newPitch: newPitch,
    });
  });
  it('should not modify campaign summary with incorrect role', async function() {
    await campaignSetup(this.factory, this.testToken);
    await expectRevert.unspecified(
      this.factory.modifyCampaignSummary(
        0,
        0,
        lorem.sentence(),
        lorem.paragraph(),
        { from: this.addr2 }
      )
    );
  });
  it('should not modify a campaign that does not exist', async function() {
    await expectRevert.unspecified(
      this.factory.modifyCampaignSummary(
        0,
        0,
        lorem.sentence(),
        lorem.paragraph()
      )
    );
  });
  it('should not modify a campaign with category that does not exist', async function() {
    await campaignSetup(this.factory, this.testToken);
    await expectRevert.unspecified(
      this.factory.modifyCampaignSummary(
        0,
        1,
        lorem.sentence(),
        lorem.paragraph()
      )
    );
  });
  it('should not modify campaign if factory is paused', async function() {
    await campaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.modifyCampaignSummary(
        0,
        1,
        lorem.sentence(),
        lorem.paragraph()
      )
    );
  });
  it('should modify campaign if factory is unpaused', async function() {
    const newTitle = lorem.sentence(),
      newPitch = lorem.paragraph();

    await campaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.modifyCampaignSummary(0, 0, newTitle, newPitch);
    expect((await this.factory.deployedCampaigns(0)).title).to.be.equal(
      newTitle
    );
    expect((await this.factory.deployedCampaigns(0)).pitch).to.be.equal(
      newPitch
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                                campaignCount                               */
  /* -------------------------------------------------------------------------- */
  it('should return total count of campaigns', async function() {
    await this.factory.createCategory('Fitness', true);
    await this.factory.createCategory('Cooking', true);
    await this.factory.createCampaign(
      300,
      0,
      lorem.sentence(),
      lorem.paragraph(),
      this.testToken.address
    );
    await this.factory.createCampaign(
      300,
      1,
      lorem.sentence(),
      lorem.paragraph(),
      this.testToken.address
    );
    expect(await this.factory.campaignCount()).to.be.bignumber.equal(
      new BN('2')
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                               destroyCampaign                              */
  /* -------------------------------------------------------------------------- */
  it('should delete campaign with right role', async function() {
    const campaignID = 0;
    await campaignSetup(this.factory, this.testToken);
    const receipt = await this.factory.destroyCampaign(campaignID);
    const campaign = await this.factory.deployedCampaigns(campaignID);
    expect(campaign.exists).to.equal(false);
    expectEvent(receipt, 'CampaignDestroyed', {
      campaignId: new BN(campaignID),
    });
  });
  it('should not delete campaign without role', async function() {
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
      this.testToken.address,
      { from: this.addr1 }
    );
    await expectRevert.unspecified(
      this.factory.destroyCampaign(campaignID, { from: this.addr2 })
    );
    const campaign = await this.factory.deployedCampaigns(campaignID);
    expect(campaign.exists).to.equal(true);
  });
  it('should not delete campaign if factory is paused', async function() {
    await campaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.destroyCampaign(0));
  });
  it('should delete campaign if factory is unpaused', async function() {
    await campaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.destroyCampaign(0);
    expect((await this.factory.deployedCampaigns(0)).exists).to.be.equal(false);
  });

  /* -------------------------------------------------------------------------- */
  /*                               featureCampaign                              */
  /* -------------------------------------------------------------------------- */
  it('should feature campaign', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    const receipt = await this.factory.featureCampaign(
      0,
      0,
      this.testToken.address,
      {
        value: 1000,
        from: this.owner,
      }
    );
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);
    expect(
      (await this.factory.deployedCampaigns(0)).featureFor
    ).to.be.bignumber.equal(new BN(`${block.timestamp + 86400}`));
    // check factory revenue
    expect(await this.factory.factoryRevenue()).to.be.bignumber.equal(
      new BN('1000')
    );
    expect(
      await this.factory.campaignRevenueFromFeatures(0)
    ).to.be.bignumber.equal(new BN('1000'));
    expectEvent(receipt, 'CampaignFeatured', {
      campaignId: new BN('0'),
      featurePackageId: new BN('0'),
      amount: new BN('1000'),
    });
  });
  it("campaign feature should fail if user isn't owner", async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await expectRevert.unspecified(
      this.factory.featureCampaign(0, 0, this.testToken.address, {
        value: 1000,
        from: this.addr2,
      })
    );
  });
  it('campaign feature should fail if campaign does not exist', async function() {
    await this.factory.createFeaturePackage('Basic', 1000, 129600); // 24hr package
    await expectRevert.unspecified(
      this.factory.featureCampaign(0, 0, this.testToken.address, {
        value: 1000,
      })
    );
  });
  it('campaign feature should fail if campaign is not active and not approved', async function() {
    await featureCampaignSetup(this.factory, this.testToken, 86400, {
      approveCampaign: false,
      activateCampaign: false,
    });
    await expectRevert.unspecified(
      this.factory.featureCampaign(0, 0, this.testToken.address, {
        value: 1000,
      })
    );
  });
  it('campaign feature should fail if campaign owner is not verified', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.toggleUserApproval(0, false);
    await expectRevert.unspecified(
      this.factory.featureCampaign(0, 0, this.testToken.address, {
        from: this.owner,
        value: 1000,
      })
    );
  });
  it('campaign feature should fail if token is not approved', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.toggleAcceptedToken(this.testToken.address, false);
    await expectRevert.unspecified(
      this.factory.featureCampaign(0, 0, this.testToken.address, {
        value: 1000,
      })
    );
  });
  it('campaign feature should fail if feature package does not exist', async function() {
    await featureCampaignSetup(this.factory, this.testToken, 86400, {
      createFeaturePackage: false,
    });
    await expectRevert.unspecified(
      this.factory.featureCampaign(0, 0, this.testToken.address, {
        value: 1000,
      })
    );
  });
  it('campaign feature should fail if payment is not enough', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await expectRevert.unspecified(
      this.factory.featureCampaign(0, 0, this.testToken.address, {
        value: 800,
      })
    );
  });
  it('campaign feature should fail if factory is paused', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.featureCampaign(0, 0, this.testToken.address, {
        value: 1000,
      })
    );
  });
  it('campaign feature should work if factory is unpaused', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    const receipt = await this.factory.featureCampaign(
      0,
      0,
      this.testToken.address,
      {
        value: 1000,
      }
    );
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);
    expect(
      (await this.factory.deployedCampaigns(0)).featureFor
    ).to.be.bignumber.equal(new BN(`${block.timestamp + 86400}`));
  });

  /* -------------------------------------------------------------------------- */
  /*                            pauseCampaignFeatured                           */
  /* -------------------------------------------------------------------------- */
  it('should pause running campaign feature', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
      from: this.owner,
    });
    const campaign = await this.factory.deployedCampaigns(0);
    await new Promise((resolve) => setTimeout(resolve, 5000));
    const receipt = await this.factory.pauseCampaignFeatured(0);
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);
    expect(
      await this.factory.pausedFeaturedCampaignTimeLeft(0)
    ).to.be.bignumber.equal(
      new BN(campaign.featureFor).sub(new BN(block.timestamp))
    );
    expect(await this.factory.featuredCampaignIsPaused(0)).to.equal(true);
    expectEvent(receipt, 'CampaignFeaturePaused', {
      campaignId: new BN('0'),
    });
  });
  it('campaign feature pause should fail if feature time is expired', async function() {
    await featureCampaignSetup(this.factory, this.testToken, 5);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
      from: this.owner,
    });
    const campaign = await this.factory.deployedCampaigns(0);
    // sleep for 6 secs to simulate time after campaign feature
    await new Promise((resolve) => setTimeout(resolve, 6000));
    await expectRevert.unspecified(this.factory.pauseCampaignFeatured(0));
    const blockNumber = await web3.eth.getBlockNumber();
    const block = await web3.eth.getBlock(blockNumber);
    expect(new BN(campaign.featureFor)).to.be.bignumber.lessThan(
      new BN(block.timestamp)
    );
    expect(await this.factory.featuredCampaignIsPaused(0)).to.equal(false);
  });
  it('campaign feature pause should fail if campaign feature is paused', async function() {
    await featureCampaignSetup(this.factory, this.testToken, 86400);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
      from: this.owner,
    });
    await this.factory.pauseCampaignFeatured(0);
    expectRevert.unspecified(this.factory.pauseCampaignFeatured(0));
    expect(await this.factory.featuredCampaignIsPaused(0)).to.equal(true);
  });
  it('campaign feature pause should fail if non owner tries to pause', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
      from: this.owner,
    });
    await expectRevert.unspecified(
      this.factory.pauseCampaignFeatured(0, { from: this.addr1 })
    );
    expect(await this.factory.featuredCampaignIsPaused(0)).to.equal(false);
  });
  it('campaign feature pause should fail if campaign does not exist', async function() {
    await expectRevert.unspecified(this.factory.pauseCampaignFeatured(0));
  });
  it('campaign feature pause should fail if campaign owner is not verified', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
      from: this.owner,
    });
    await this.factory.toggleUserApproval(0, false);
    await expectRevert.unspecified(this.factory.pauseCampaignFeatured(0));
    expect(await this.factory.featuredCampaignIsPaused(0)).to.equal(false);
  });
  it('campaign feature pause should fail if factory is paused', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
      from: this.owner,
    });
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.pauseCampaignFeatured(0));
  });
  it('campaign feature pause should work if factory is unpaused', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
    });
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.pauseCampaignFeatured(0);
    expect(await this.factory.featuredCampaignIsPaused(0)).to.be.equal(true);
  });

  /* -------------------------------------------------------------------------- */
  /*                           unpauseCampaignFeatured                          */
  /* -------------------------------------------------------------------------- */
  it('should unpause paused campaign feature', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
      from: this.owner,
    });

    await new Promise((resolve) => setTimeout(resolve, 6000));

    await this.factory.pauseCampaignFeatured(0);

    const timeLeft = await this.factory.pausedFeaturedCampaignTimeLeft(0);

    const campaign = await this.factory.deployedCampaigns(0);

    const receipt = await this.factory.unpauseCampaignFeatured(0);

    expect(
      new BN((await this.factory.deployedCampaigns(0)).featureFor)
    ).to.be.bignumber.equal(new BN(campaign.featureFor).add(new BN(timeLeft)));
    expect(await this.factory.featuredCampaignIsPaused(0)).to.be.equal(false);
    expect(
      new BN(await this.factory.pausedFeaturedCampaignTimeLeft(0))
    ).to.be.bignumber.equal(new BN('0'));

    expectEvent(receipt, 'CampaignFeatureUnpaused', {
      campaignId: new BN('0'),
      timeLeft: new BN('0'),
    });
  });
  it('campaign unpause feature should fail if not campaign owner', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
    });
    await this.factory.pauseCampaignFeatured(0);
    await expectRevert.unspecified(
      this.factory.unpauseCampaignFeatured(0, { from: this.addr1 })
    );
  });
  it('campaign unpause feature should fail if campaign does not exist', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
    });
    await this.factory.pauseCampaignFeatured(0);
    await this.factory.destroyCampaign(0);

    await expectRevert.unspecified(this.factory.unpauseCampaignFeatured(0));
  });
  it('campaign unpause feature should fail if user is not verified', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
    });
    await this.factory.pauseCampaignFeatured(0);
    await this.factory.toggleUserApproval(0, false);
    await expectRevert.unspecified(this.factory.unpauseCampaignFeatured(0));
  });
  it('campaign unpause feature should fail if factory is paused', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
    });
    await this.factory.pauseCampaignFeatured(0);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.unpauseCampaignFeatured(0));
  });
  it('campaign unpause feature should work if factory is unpaused', async function() {
    await featureCampaignSetup(this.factory, this.testToken);
    await this.factory.featureCampaign(0, 0, this.testToken.address, {
      value: 1000,
      from: this.owner,
    });
    await this.factory.pauseCampaignFeatured(0);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.unpauseCampaignFeatured(0);
    expect(await this.factory.featuredCampaignIsPaused(0)).to.be.equal(false);
  });
};
