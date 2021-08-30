// test/campaign.test.js
export {};
const { expect, assert } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const TestToken = artifacts.require('TestToken');

interface CampaignFactoryConfig {
  deadlineStrikesAllowed: number;
  maxDeadlineExtension: number;
  minDeadlineExtension: number;
  minimumContributionAllowed: number;
  maximumContributionAllowed: number;
  minRequestDuration: number;
  maxRequestDuration: number;
  minimumRequestAmountAllowed: number;
  maximumRequestAmountAllowed: number;
  reviewThresholdMark: number;
  minimumCampaignTarget: number;
  maximumCampaignTarget: number;
}

interface CampaignSetupConfig {
  approveCampaign?: boolean;
  activateCampaign?: boolean;
  target?: number;
  minimumContribution?: number;
  duration?: number;
  goalType?: number;
  allowContributionAfterTargetIsMet?: boolean;
  from?: string;
}

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
      minimumRequestAmountAllowed: 500,
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
    await this.factory.signUp({
      from: this.addr1,
    });
    await this.factory.toggleUserApproval(0, true, { from: this.root });
    await this.factory.toggleUserApproval(1, true, { from: this.root });
    await this.factory.toggleUserApproval(2, true, { from: this.root });
    await this.factory.createCampaign(0, {
      from: this.campaignOwner,
    });
    const { campaign } = await this.factory.deployedCampaigns(0);
    this.campaignInstance = await Campaign.at(campaign);
    this.campaignID = await this.campaignInstance.campaignID();

    await this.testToken.increaseAllowance(
      this.campaignInstance.address,
      10000,
      { from: this.root }
    );
    await this.testToken.increaseAllowance(
      this.campaignInstance.address,
      10000,
      { from: this.addr1 }
    );
    await this.testToken.transfer(this.addr1, 10000, {
      from: this.root,
    });

    this.approvedCampaignSetup = async ({
      approveCampaign = true,
      activateCampaign = true,
      target = 20000,
      minimumContribution = 1,
      duration = 86400,
      goalType = 1,
      allowContributionAfterTargetIsMet = true,
      from = this.campaignOwner,
    }: CampaignSetupConfig): Promise<any> => {
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
      await this.campaignInstance.toggleWithdrawalState(false, {
        from: this.root,
      });
      await this.campaignInstance.setCampaignState(1, { from: this.root });
    };
  });

  // it('deployer owns the campaign', async function() {
  //   assert.equal(await this.campaignInstance.root(), this.campaignOwner);
  // });

  // it('campaign is paused on initialization', async function() {
  //   assert.equal(await this.campaignInstance.paused(), true);
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                             setCampaignSettings                            */
  // /* -------------------------------------------------------------------------- */
  // it('campaign owner can set campaign settings', async function() {
  //   const receipt = await this.campaignInstance.setCampaignSettings(
  //     20000,
  //     1,
  //     604800,
  //     1,
  //     this.testToken.address,
  //     false,
  //     {
  //       from: this.campaignOwner,
  //     }
  //   );
  //   const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

  //   expect(await this.campaignInstance.target()).to.be.bignumber.equal(
  //     new BN('20000')
  //   );
  //   expect(
  //     await this.campaignInstance.minimumContribution()
  //   ).to.be.bignumber.equal(new BN('1'));
  //   expect(await this.campaignInstance.deadline()).to.be.bignumber.equal(
  //     new BN(`${+block.timestamp + 604800}`)
  //   );
  //   expect(
  //     await this.campaignInstance.deadlineSetTimes()
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect(await this.campaignInstance.goalType()).to.be.bignumber.equal(
  //     new BN('1')
  //   );
  //   expect(await this.campaignInstance.acceptedToken()).to.be.equal(
  //     this.testToken.address
  //   );
  //   expect(
  //     await this.campaignInstance.allowContributionAfterTargetIsMet()
  //   ).to.be.equal(false);
  //   expectEvent(receipt, 'CampaignSettingsUpdated', {
  //     campaignId: this.campaignID,
  //     minimumContribution: new BN('1'),
  //     deadline: new BN('604800'),
  //     goalType: new BN('1'),
  //     token: this.testToken.address,
  //   });
  // });
  // it('campaign settings modification should work for factory even if campaign has been approved', async function() {
  //   // this.factory.toggleCampaignApproval(this.campaignID, true, {
  //   //   from: this.root,
  //   // });
  //   // this.factory.toggleCampaignActive(this.campaignID, true, {
  //   //   from: this.root,
  //   // });
  //   await this.campaignInstance.setCampaignSettings(
  //     300000,
  //     1,
  //     604800,
  //     1,
  //     this.testToken.address,
  //     false,
  //     {
  //       from: this.root,
  //     }
  //   );
  //   expect(await this.campaignInstance.target()).to.be.bignumber.equal(
  //     new BN('300000')
  //   );
  // });
  // it('campaign settings modification should fail if campaign has been approved', async function() {
  //   this.factory.toggleCampaignApproval(this.campaignID, true, {
  //     from: this.root,
  //   });
  //   this.factory.toggleCampaignActive(this.campaignID, true, {
  //     from: this.root,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.setCampaignSettings(
  //       300000,
  //       1,
  //       604800,
  //       1,
  //       this.testToken.address,
  //       false,
  //       {
  //         from: this.campaignOwner,
  //       }
  //     )
  //   );
  // });
  // it('campaign settings modification should fail if the token has not being approved', async function() {
  //   await this.factory.toggleAcceptedToken(this.testToken.address, false, {
  //     from: this.root,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.setCampaignSettings(
  //       300000,
  //       1,
  //       604800,
  //       1,
  //       this.testToken.address,
  //       false,
  //       {
  //         from: this.campaignOwner,
  //       }
  //     )
  //   );
  // });
  // it('campaign settings modification should fail if minimum contribution is larger than maximum or less than minimum allowed from factory', async function() {
  //   await this.factory.setCampaignTransactionConfig(
  //     'minimumContributionAllowed',
  //     2,
  //     {
  //       from: this.root,
  //     }
  //   );
  //   await expectRevert.unspecified(
  //     this.campaignInstance.setCampaignSettings(
  //       300000,
  //       1,
  //       604800,
  //       1,
  //       this.testToken.address,
  //       false,
  //       {
  //         from: this.campaignOwner,
  //       }
  //     )
  //   );
  //   await expectRevert.unspecified(
  //     this.campaignInstance.setCampaignSettings(
  //       300000,
  //       20000,
  //       604800,
  //       1,
  //       this.testToken.address,
  //       false,
  //       {
  //         from: this.campaignOwner,
  //       }
  //     )
  //   );
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                               extendDeadline                               */
  // /* -------------------------------------------------------------------------- */
  // it('should extend the campaign duration', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 2,
  //     from: this.campaignOwner,
  //   });
  //   await new Promise((resolve) => setTimeout(resolve, 3000));
  //   const receipt = await this.campaignInstance.extendDeadline(86400, {
  //     from: this.campaignOwner,
  //   });
  //   const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

  //   expect(await this.campaignInstance.deadline()).to.be.bignumber.equal(
  //     new BN(`${+block.timestamp + 86400}`)
  //   );
  //   expect(
  //     await this.campaignInstance.deadlineSetTimes()
  //   ).to.be.bignumber.equal(new BN('1'));
  //   expectEvent(receipt, 'CampaignDeadlineExtended', {
  //     campaignId: new BN('0'),
  //     time: new BN('86400'),
  //   });
  // });
  // it("duration extension should fail if the campaign isn't active or enabled", async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 2,
  //     from: this.campaignOwner,
  //     approveCampaign: false,
  //     activateCampaign: false,
  //   });
  //   await new Promise((resolve) => setTimeout(resolve, 3000));
  //   await expectRevert.unspecified(
  //     this.campaignInstance.extendDeadline(86400, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });
  // it("duration extension should fail if the campaign duration hasn't expired", async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 86400,
  //     from: this.campaignOwner,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.extendDeadline(86400, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });
  // it('duration extension should fail if ability to extend has been exhausted', async function() {
  //   await this.factory.setCampaignTransactionConfig(
  //     'deadlineStrikesAllowed',
  //     1,
  //     { from: this.root }
  //   );
  //   await this.approvedCampaignSetup({
  //     duration: 2,
  //     from: this.campaignOwner,
  //   });
  //   await new Promise((resolve) => setTimeout(resolve, 3000));
  //   await this.campaignInstance.extendDeadline(86400, {
  //     from: this.campaignOwner,
  //   });

  //   expect(
  //     await this.campaignInstance.deadlineSetTimes()
  //   ).to.be.bignumber.equal(new BN('1'));
  //   await expectRevert.unspecified(
  //     this.campaignInstance.extendDeadline(86400, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });
  // it('duration extension should fail if the time to extend by is less or greater than allowed from factory', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 3,
  //     from: this.campaignOwner,
  //   });
  //   await new Promise((resolve) => setTimeout(resolve, 3000));
  //   await expectRevert.unspecified(
  //     this.campaignInstance.extendDeadline(604801, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                             setDeadlineSetTimes                            */
  // /* -------------------------------------------------------------------------- */
  // it('should set the number of times a campaign manager has extended deadline', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 86400,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.setDeadlineSetTimes(2, { from: this.root });
  //   expect(
  //     await this.campaignInstance.deadlineSetTimes()
  //   ).to.be.bignumber.equal(new BN('2'));
  // });
  // it('should fail if the ability to extend campaign duration is called by the campaign owner', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 86400,
  //     from: this.campaignOwner,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.setDeadlineSetTimes(3000, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                                createReward                                */
  // /* -------------------------------------------------------------------------- */
  // it('should create a reward', async function() {
  //   await this.campaignInstance.unpauseCampaign({ from: this.root });
  //   const receipt = await this.campaignInstance.createReward(
  //     100,
  //     86400,
  //     10,
  //     true,
  //     {
  //       from: this.campaignOwner,
  //     }
  //   );
  //   expect(
  //     (await this.campaignInstance.rewards(0)).value
  //   ).to.be.bignumber.equal(new BN('100'));
  //   expect(
  //     (await this.campaignInstance.rewards(0)).deliveryDate
  //   ).to.be.bignumber.equal(new BN('86400'));
  //   expect(
  //     (await this.campaignInstance.rewards(0)).stock
  //   ).to.be.bignumber.equal(new BN('10'));
  //   expect((await this.campaignInstance.rewards(0)).active).to.be.equal(true);

  //   expectEvent(receipt, 'RewardCreated', {
  //     rewardId: new BN('0'),
  //     campaignId: new BN(this.campaignID),
  //     value: new BN('100'),
  //     deliveryDate: new BN('86400'),
  //     stock: new BN('10'),
  //     active: true,
  //   });
  // });
  // it('reward creation should fail if the cost is less than minimum allowed contribution', async function() {
  //   const globalMinimumContributionAllowed = 200;
  //   const campaignMinimumContributionAllowed = 300;

  //   await this.factory.setCampaignTransactionConfig(
  //     'minimumContributionAllowed',
  //     globalMinimumContributionAllowed,
  //     { from: this.root }
  //   );
  //   await this.campaignInstance.unpauseCampaign({ from: this.root });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.createReward(100, 86400, 10, true, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });
  // it('reward creation should fail if the cost is greater than maximum allowed contribution', async function() {
  //   const globalMaximumContributionAllowed = 1000;
  //   const campaignMaximumContributionAllowed = 1000;
  //   const rewardCost = 20000;

  //   await this.factory.setCampaignTransactionConfig(
  //     'maximumContributionAllowed',
  //     globalMaximumContributionAllowed,
  //     { from: this.root }
  //   );
  //   await this.campaignInstance.unpauseCampaign({ from: this.root });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.createReward(rewardCost, 86400, 10, true, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                                modifyReward                                */
  // /* -------------------------------------------------------------------------- */
  // it('should modify a reward', async function() {
  //   await this.campaignInstance.unpauseCampaign({ from: this.root });
  //   await this.campaignInstance.createReward(500, 86400, 10, true, {
  //     from: this.campaignOwner,
  //   });
  //   const receipt = await this.campaignInstance.modifyReward(
  //     0,
  //     200,
  //     86400,
  //     3,
  //     false
  //   );
  //   expect(
  //     (await this.campaignInstance.rewards(0)).value
  //   ).to.be.bignumber.equal(new BN('200'));
  //   expect(
  //     (await this.campaignInstance.rewards(0)).deliveryDate
  //   ).to.be.bignumber.equal(new BN('86400'));
  //   expect(
  //     (await this.campaignInstance.rewards(0)).stock
  //   ).to.be.bignumber.equal(new BN('3'));
  //   expect((await this.campaignInstance.rewards(0)).active).to.be.equal(false);

  //   expectEvent(receipt, 'RewardModified', {
  //     rewardId: new BN('0'),
  //     campaignId: new BN(this.campaignID),
  //     value: new BN('200'),
  //     deliveryDate: new BN('86400'),
  //     stock: new BN('3'),
  //     active: false,
  //   });
  // });
  // it('should increase reward stock count', async function() {
  //   await this.campaignInstance.unpauseCampaign({ from: this.root });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   const receipt = await this.campaignInstance.increaseRewardStock(0, 1);
  //   expect(
  //     (await this.campaignInstance.rewards(0)).stock
  //   ).to.be.bignumber.equal(new BN('4'));
  //   expectEvent(receipt, 'RewardStockIncreased', {
  //     rewardId: new BN('0'),
  //     campaignId: new BN(this.campaignID),
  //     count: new BN('1'),
  //   });
  // });
  // it('reward modification should fail if it has backers', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 86400,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 600,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.modifyReward(0, 200, 86400, 3, false, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });
  // it("reward modification should fail if the reward doesn't exist", async function() {
  //   await this.campaignInstance.unpauseCampaign({ from: this.root });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.modifyReward(0, 200, 86400, 3, false, {
  //       from: this.campaignOwner,
  //     })
  //   );
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                                destroyReward                               */
  // /* -------------------------------------------------------------------------- */
  // it('should delete a reward', async function() {
  //   await this.campaignInstance.unpauseCampaign({ from: this.root });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   const receipt = await this.campaignInstance.destroyReward(0, {
  //     from: this.campaignOwner,
  //   });

  //   expect(
  //     (await this.campaignInstance.rewards(0)).value
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect(
  //     (await this.campaignInstance.rewards(0)).deliveryDate
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect(
  //     (await this.campaignInstance.rewards(0)).stock
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect((await this.campaignInstance.rewards(0)).active).to.be.equal(false);

  //   expectEvent(receipt, 'RewardDestroyed', {
  //     rewardId: new BN('0'),
  //     campaignId: new BN(this.campaignID),
  //   });
  // });
  // it('reward deletion should fail if the reward has backers', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 600,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.destroyReward(0, { from: this.campaignOwner })
  //   );
  // });
  // it("reward deletion should fail if the reward doesn't exist", async function() {
  //   await this.campaignInstance.unpauseCampaign({ from: this.root });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.destroyReward(0, { from: this.campaignOwner })
  //   );
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                             campaignSentReward                             */
  // /* -------------------------------------------------------------------------- */
  // it('should mark a reward as delivered', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 600,
  //   });
  //   const receipt = await this.campaignInstance.campaignSentReward(0, true, {
  //     from: this.campaignOwner,
  //   });

  //   expect(
  //     (await this.campaignInstance.rewardRecipients(0))
  //       .deliveryConfirmedByCampaign
  //   ).to.be.equal(true);
  //   expectEvent(receipt, 'RewarderApproval', {
  //     rewardRecipientId: new BN('0'),
  //     campaignId: new BN(this.campaignID),
  //     status: true,
  //   });
  // });
  // it('reward delivery update should fail if not called by the campaign owner', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 600,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.campaignSentReward(0, true, {
  //       from: this.addr3,
  //     })
  //   );
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                         userReceivedCampaignReward                         */
  // /* -------------------------------------------------------------------------- */
  // it('should mark a reward as received', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 600,
  //   });
  //   await this.campaignInstance.campaignSentReward(0, true, {
  //     from: this.campaignOwner,
  //   });
  //   const receipt = await this.campaignInstance.userReceivedCampaignReward(0, {
  //     from: this.root,
  //   });

  //   expect(
  //     (await this.campaignInstance.rewardRecipients(0)).deliveryConfirmedByUser
  //   ).to.be.equal(true);
  //   expectEvent(receipt, 'RewardRecipientApproval', {
  //     rewardRecipientId: new BN('0'),
  //     campaignId: new BN(this.campaignID),
  //   });
  // });
  // it('reward received should fail if reward delivery is marked false', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 600,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.userReceivedCampaignReward(0, {
  //       from: this.root,
  //     })
  //   );
  // });
  // it("reward received should fail if user isn't the owner of the reward", async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 600,
  //   });
  //   await this.campaignInstance.campaignSentReward(0, true, {
  //     from: this.campaignOwner,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.userReceivedCampaignReward(0, {
  //       from: this.addr1,
  //     })
  //   );
  // });
  // it("reward received should fail if the user isn't an approver", async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 600,
  //   });
  //   await this.campaignInstance.campaignSentReward(0, true, {
  //     from: this.campaignOwner,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.userReceivedCampaignReward(0, {
  //       from: this.addr1,
  //     })
  //   );
  // });

  // /* -------------------------------------------------------------------------- */
  // /*                                 contribute                                 */
  // /* -------------------------------------------------------------------------- */
  // it('should contribute into the campaign and make user an approver', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   const receipt = await this.campaignInstance.contribute(
  //     this.testToken.address,
  //     0,
  //     false,
  //     {
  //       from: this.root,
  //       value: 600,
  //     }
  //   );

  //   expect(await this.campaignInstance.approvers(this.root)).to.be.equal(true);
  //   expect(await this.campaignInstance.approversCount()).to.be.bignumber.equal(
  //     new BN('1')
  //   );
  //   expect(
  //     await this.campaignInstance.totalCampaignContribution()
  //   ).to.be.bignumber.equal(new BN('600'));
  //   expect(
  //     await this.campaignInstance.userTotalContribution(this.root)
  //   ).to.be.bignumber.equal(new BN('600'));
  //   expectEvent(receipt, 'ContributionMade', {
  //     campaignId: new BN(this.campaignID),
  //     userId: new BN(await this.factory.userID(this.root)),
  //     amount: new BN('600'),
  //   });
  // });
  // it('should emit an event and set campaign state set to live when the campagin target is met', async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     target: 5000,
  //     from: this.campaignOwner,
  //   });
  //   const receipt = await this.campaignInstance.contribute(
  //     this.testToken.address,
  //     0,
  //     false,
  //     {
  //       from: this.root,
  //       value: 5000,
  //     }
  //   );
  //   // check campaign state
  //   // where 2 is LIVE
  //   expect(
  //     (await this.campaignInstance.campaignState()).toString()
  //   ).to.be.equal('2');
  //   expectEvent(receipt, 'TargetMet', {
  //     campaignId: new BN(this.campaignID),
  //     amount: new BN('5000'),
  //   });
  // });
  // it("should fail if token used for contribution isn't accepted", async function() {
  //   await this.approvedCampaignSetup({
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   });
  //   await expectRevert.unspecified(
  //     this.campaignInstance.contribute(
  //       '0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b',
  //       0,
  //       false,
  //       {
  //         from: this.root,
  //         value: 5000,
  //       }
  //     )
  //   );
  // });
  // it('should fail if contribution amount is below minimum or above maximum', async function() {
  //   let config: CampaignSetupConfig = {
  //     duration: 184000,
  //     minimumContribution: 10,
  //     from: this.campaignOwner,
  //   };
  //   await this.approvedCampaignSetup(config);
  //   await expectRevert.unspecified(
  //     this.campaignInstance.contribute(this.testToken.address, 0, false, {
  //       from: this.root,
  //       value: 1,
  //     })
  //   );
  //   await expectRevert.unspecified(
  //     this.campaignInstance.contribute(this.testToken.address, 0, false, {
  //       from: this.root,
  //       value: 100000,
  //     })
  //   );
  // });
  // it('contribution should fail if campaign does not allow contribution after target is met', async function() {
  //   let config: CampaignSetupConfig = {
  //     duration: 184000,
  //     target: 6000,
  //     minimumContribution: 10,
  //     allowContributionAfterTargetIsMet: false,
  //     from: this.campaignOwner,
  //   };
  //   await this.approvedCampaignSetup(config);
  //   await expectRevert.unspecified(
  //     this.campaignInstance.contribute(this.testToken.address, 0, false, {
  //       from: this.root,
  //       value: 7000,
  //     })
  //   );
  // });
  // it('should mark a contributor eligible for a reward', async function() {
  //   let config: CampaignSetupConfig = {
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   };
  //   await this.approvedCampaignSetup(config);
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   const receipt = await this.campaignInstance.contribute(
  //     this.testToken.address,
  //     0,
  //     true,
  //     {
  //       from: this.root,
  //       value: 1000,
  //     }
  //   );

  //   expect(
  //     (await this.campaignInstance.rewardRecipients(0)).rewardId
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect((await this.campaignInstance.rewardRecipients(0)).user).to.be.equal(
  //     this.root
  //   );
  //   expect(
  //     (await this.campaignInstance.rewardRecipients(0))
  //       .deliveryConfirmedByCampaign
  //   ).to.be.equal(false);
  //   expect(
  //     (await this.campaignInstance.rewardRecipients(0)).deliveryConfirmedByUser
  //   ).to.be.equal(false);
  //   expect(
  //     await this.campaignInstance.userRewardCount(this.root)
  //   ).to.be.bignumber.equal(new BN('1'));
  //   expect(
  //     await this.campaignInstance.rewardToRewardRecipientCount(0)
  //   ).to.be.bignumber.equal(new BN('1'));

  //   expectEvent(receipt, 'RewardRecipientAdded', {
  //     rewardId: new BN('0'),
  //     campaignId: new BN(this.campaignID),
  //     user: new BN(await this.factory.userID(this.root)),
  //     amount: new BN('1000'),
  //   });
  // });

  /* -------------------------------------------------------------------------- */
  /*                           withdrawOwnContribution                          */
  /* -------------------------------------------------------------------------- */
  // it('should withdraw user contribution and remove the user as a contributor', async function() {
  //   let config: CampaignSetupConfig = {
  //     duration: 184000,
  //     from: this.campaignOwner,
  //   };
  //   await this.approvedCampaignSetup(config);
  //   await this.campaignInstance.createReward(500, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.createReward(700, 86400, 3, true, {
  //     from: this.campaignOwner,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
  //     from: this.root,
  //     value: 1000,
  //   });
  //   await this.campaignInstance.contribute(this.testToken.address, 1, true, {
  //     from: this.root,
  //     value: 700,
  //   });
  //   const receipt = await this.campaignInstance.withdrawOwnContribution(
  //     1700,
  //     this.root,
  //     {
  //       from: this.root,
  //     }
  //   );

  //   expect(await this.campaignInstance.approvers(this.root)).to.be.equal(false);
  //   expect(await this.campaignInstance.approversCount()).to.be.bignumber.equal(
  //     new BN('0')
  //   );
  //   expect(
  //     await this.campaignInstance.userRewardCount(this.root)
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect(
  //     await this.campaignInstance.rewardToRewardRecipientCount(0)
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect(
  //     await this.campaignInstance.rewardToRewardRecipientCount(1)
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect(
  //     await this.campaignInstance.userTotalContribution(this.root)
  //   ).to.be.bignumber.equal(new BN('0'));
  //   expect(
  //     await this.campaignInstance.totalCampaignContribution()
  //   ).to.be.bignumber.equal(new BN('0'));

  //   expectEvent(receipt, 'ContributionWithdrawn', {
  //     campaignId: new BN(this.campaignID),
  //     amount: new BN('1700'),
  //     sender: this.root,
  //   });
  // });
  it('should withdraw user contribution if the campaign state is in review mode and there are left over funds', async function() {
    let config: CampaignSetupConfig = {
      duration: 2,
      from: this.campaignOwner,
    };
    await this.approvedCampaignSetup(config);
    await this.campaignInstance.contribute(this.testToken.address, 0, false, {
      from: this.root,
      value: 700,
    });
    await this.campaignInstance.contribute(this.testToken.address, 0, false, {
      from: this.addr1,
      value: 1000,
    });
    await new Promise((resolve) => setTimeout(resolve, 3000));
    await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
      from: this.campaignOwner,
    });
    await this.campaignInstance.voteOnRequest(0, { from: this.root });
    await this.campaignInstance.voteOnRequest(0, { from: this.addr1 });
    await this.campaignInstance.finalizeRequest(0, {
      from: this.campaignOwner,
    });
    await this.campaignInstance.reviewMode({ from: this.campaignOwner });
    const receipt = await this.campaignInstance.withdrawOwnContribution(
      400,
      this.root,
      {
        from: this.root,
      }
    );
    // console.log(await this.campaignInstance.userBalanceSoFar(this.root));
    // expect(
    //   await this.campaignInstance.userTotalContribution(this.root)
    // ).to.be.bignumber.equal(new BN('500'));
    // expect(
    //   await this.campaignInstance.totalCampaignContribution()
    // ).to.be.bignumber.equal(new BN('0'));
    // expectEvent(receipt, 'ContributionWithdrawn', {
    //   campaignId: new BN(this.campaignID),
    //   userId: new BN(await this.factory.userID(this.root)),
    //   amount: new BN('200'),
    //   sender: this.root,
    // });
  });
});
