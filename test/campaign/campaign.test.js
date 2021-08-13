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

    this.factorySettings = {
      deadlineStrikesAllowed: 3,
      maxDeadlineExtension: 604800,
      minDeadlineExtension: 86400,
      minimumContributionAllowed: 1,
      maximumContributionAllowed: 10000,
      minRequestDuration: 86400,
      maxRequestDuration: 604800,
      minimumRequestAmountAllowed: 1000,
      maximumRequestAmountAllowed: 10000,
      reviewThresholdMark: 80,
      minimumCampaignTarget: 5000,
      maximumCampaignTarget: 10000000,
    };
    await this.factory.setFactoryConfig(
      factoryWallet,
      this.campaignImplementation.address,
      { from: this.root }
    );
    await Promise.all(
      Object.keys(this.factorySettings).map(async (setting) => {
        await this.factory.setCampaignTransactionConfig(
          setting,
          this.factorySettings[setting],
          { from: this.root }
        );
      })
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
    await this.factory.toggleUserApproval(0, true, { from: this.root });
    await this.factory.toggleUserApproval(1, true, { from: this.root });
    await this.factory.createCampaign(0, {
      from: this.campaignOwner,
    });
    const { campaign } = await this.factory.deployedCampaigns(0);
    this.campaignInstance = await Campaign.at(campaign);
    this.campaignID = await this.campaignInstance.campaignID();

    this.approvedCampaignSetup = async ({
      approveCampaign = true,
      activateCampaign = true,
      target = 20000,
      minimumContribution = 1,
      duration = 86400,
      goalType = 1,
      allowContributionAfterTargetIsMet = true,
      from,
    } = {}) => {
      await this.campaignInstance.setCampaignSettings(
        target,
        minimumContribution,
        duration,
        goalType,
        this.testToken.address,
        allowContributionAfterTargetIsMet,
        {
          from,
        }
      );

      if (approveCampaign) {
        await this.factory.toggleCampaignApproval(this.campaignID, true, {
          from: this.root,
        });
      }

      if (activateCampaign) {
        await this.factory.toggleCampaignActive(this.campaignID, true, {
          from: this.root,
        });
      }

      await this.campaignInstance.unpauseCampaign({ from: this.root });
      // await this.campaignInstance.set
    };
  });

  it('deployer owns the campaign', async function() {
    assert.equal(await this.campaignInstance.root(), this.campaignOwner);
  });

  it('campaign is paused on initialization', async function() {
    assert.equal(await this.campaignInstance.paused(), true);
  });

  /* -------------------------------------------------------------------------- */
  /*                             setCampaignSettings                            */
  /* -------------------------------------------------------------------------- */
  it('campaign owner can set campaign settings', async function() {
    const receipt = await this.campaignInstance.setCampaignSettings(
      20000,
      1,
      604800,
      1,
      this.testToken.address,
      false,
      {
        from: this.campaignOwner,
      }
    );

    expect(await this.campaignInstance.target()).to.be.bignumber.equal(
      new BN('20000')
    );
    expect(
      await this.campaignInstance.minimumContribution()
    ).to.be.bignumber.equal(new BN('1'));
    expect(await this.campaignInstance.deadline()).to.be.bignumber.equal(
      new BN('604800')
    );
    expect(await this.campaignInstance.deadline()).to.be.bignumber.equal(
      new BN('604800')
    );
    expect(await this.campaignInstance.goalType()).to.be.bignumber.equal(
      new BN('1')
    );
    expect(await this.campaignInstance.acceptedToken()).to.be.equal(
      this.testToken.address
    );
    expect(
      await this.campaignInstance.allowContributionAfterTargetIsMet()
    ).to.be.equal(false);
    expectEvent(receipt, 'CampaignSettingsUpdated', {
      campaignId: this.campaignID,
      minimumContribution: new BN('1'),
      deadline: new BN('604800'),
      goalType: new BN('1'),
      token: this.testToken.address,
    });
  });
  it('campaign settings modification should work for factory even if campaign has been approved', async function() {
    // this.factory.toggleCampaignApproval(this.campaignID, true, {
    //   from: this.root,
    // });
    // this.factory.toggleCampaignActive(this.campaignID, true, {
    //   from: this.root,
    // });
    await this.campaignInstance.setCampaignSettings(
      300000,
      1,
      604800,
      1,
      this.testToken.address,
      false,
      {
        from: this.root,
      }
    );
    expect(await this.campaignInstance.target()).to.be.bignumber.equal(
      new BN('300000')
    );
  });
  it('campaign settings modification should fail if campaign has been approved', async function() {
    this.factory.toggleCampaignApproval(this.campaignID, true, {
      from: this.root,
    });
    this.factory.toggleCampaignActive(this.campaignID, true, {
      from: this.root,
    });
    await expectRevert.unspecified(
      this.campaignInstance.setCampaignSettings(
        300000,
        1,
        604800,
        1,
        this.testToken.address,
        false,
        {
          from: this.campaignOwner,
        }
      )
    );
  });
  it('campaign settings modification should fail if the token has not being approved', async function() {
    await this.factory.toggleAcceptedToken(this.testToken.address, false, {
      from: this.root,
    });
    await expectRevert.unspecified(
      this.campaignInstance.setCampaignSettings(
        300000,
        1,
        604800,
        1,
        this.testToken.address,
        false,
        {
          from: this.campaignOwner,
        }
      )
    );
  });
  it('campaign settings modification should fail if minimum contribution is larger than maximum or less than minimum allowed from factory', async function() {
    await this.factory.setCampaignTransactionConfig(
      'minimumContributionAllowed',
      2,
      {
        from: this.root,
      }
    );
    await expectRevert.unspecified(
      this.campaignInstance.setCampaignSettings(
        300000,
        1,
        604800,
        1,
        this.testToken.address,
        false,
        {
          from: this.campaignOwner,
        }
      )
    );
    await expectRevert.unspecified(
      this.campaignInstance.setCampaignSettings(
        300000,
        20000,
        604800,
        1,
        this.testToken.address,
        false,
        {
          from: this.campaignOwner,
        }
      )
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                               extendDeadline                               */
  /* -------------------------------------------------------------------------- */
  it('should extend the campaign duration', async function() {
    await this.approvedCampaignSetup({
      duration: 6,
      from: this.campaignOwner,
    });
    await new Promise((resolve) => setTimeout(resolve, 5000));
    await this.campaignInstance.extendDeadline(86400, {
      from: this.campaignOwner,
    });

    expect(await this.campaignInstance.deadline()).to.be.bignumber.equal(
      new BN('86400')
    );
    expect(
      await this.campaignInstance.deadlineSetTimes()
    ).to.be.bignumber.equal(new BN('1'));
  });
});
