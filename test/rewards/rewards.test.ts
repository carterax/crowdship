export {};
const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const Factory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignRewards = artifacts.require('CampaignRewards');
const TestToken = artifacts.require('TestToken');

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

contract(
  'CampaignRewards',
  function ([campaignOwner, root, factoryWallet, addr1, addr2, addr3]) {
    beforeEach(async function () {
      this.root = root;
      this.campaignOwner = campaignOwner;
      this.factoryWallet = factoryWallet;
      this.addr1 = addr1;
      this.addr2 = addr2;
      this.addr3 = addr3;
      this.campaignImplementation = await Campaign.new();
      this.campaignRewardsImplementation = await CampaignRewards.new();

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
        maximumContributionAllowed: 100000,
        minRequestDuration: 86400,
        maxRequestDuration: 604800,
        minimumRequestAmountAllowed: 500,
        maximumRequestAmountAllowed: 10000,
        reviewThresholdMark: 80,
        minimumCampaignTarget: 5000,
        maximumCampaignTarget: 10000000,
        requestFinalizationThreshold: 51,
      };
      await this.factory.setFactoryConfig(
        factoryWallet,
        this.campaignImplementation.address,
        this.campaignRewardsImplementation.address,
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
      const { campaign, campaignRewards } =
        await this.factory.deployedCampaigns(0);
      this.campaignInstance = await Campaign.at(campaign);
      this.campaignID = await this.campaignInstance.campaignID();

      // rewards contract setup
      this.rewardsInstance = await CampaignRewards.at(campaignRewards);

      await this.testToken.increaseAllowance(
        this.campaignInstance.address,
        100000,
        { from: this.root }
      );
      await this.testToken.increaseAllowance(
        this.campaignInstance.address,
        100000,
        { from: this.addr1 }
      );
      await this.testToken.transfer(this.addr1, 100000, {
        from: this.root,
      });
      await this.testToken.increaseAllowance(
        this.campaignInstance.address,
        100000,
        { from: this.campaignOwner }
      );
      await this.testToken.transfer(this.campaignOwner, 100000, {
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

    /* -------------------------------------------------------------------------- */
    /*                                createReward                                */
    /* -------------------------------------------------------------------------- */
    it('should create a reward', async function () {
      const receipt = await this.rewardsInstance.createReward(
        100,
        86400,
        10,
        true,
        {
          from: this.campaignOwner,
        }
      );
      expect(
        (await this.rewardsInstance.rewards(0)).value
      ).to.be.bignumber.equal(new BN('100'));
      expect(
        (await this.rewardsInstance.rewards(0)).deliveryDate
      ).to.be.bignumber.equal(new BN('86400'));
      expect(
        (await this.rewardsInstance.rewards(0)).stock
      ).to.be.bignumber.equal(new BN('10'));
      expect((await this.rewardsInstance.rewards(0)).active).to.be.equal(true);

      expectEvent(receipt, 'RewardCreated', {
        rewardId: new BN('0'),
        campaignId: new BN(this.campaignID),
        value: new BN('100'),
        deliveryDate: new BN('86400'),
        stock: new BN('10'),
        active: true,
        sender: this.campaignOwner,
      });
    });
    it('reward creation should fail if the cost is less than minimum allowed contribution', async function () {
      const globalMinimumContributionAllowed = 200;
      const campaignMinimumContributionAllowed = 300;

      await this.factory.setCampaignTransactionConfig(
        'minimumContributionAllowed',
        globalMinimumContributionAllowed,
        { from: this.root }
      );

      await expectRevert(
        this.rewardsInstance.createReward(100, 86400, 10, true, {
          from: this.campaignOwner,
        }),
        'amount too low'
      );
    });
    it('reward creation should fail if the cost is greater than maximum allowed contribution', async function () {
      const globalMaximumContributionAllowed = 1000;
      const campaignMaximumContributionAllowed = 1000;
      const rewardCost = 20000;

      await this.factory.setCampaignTransactionConfig(
        'maximumContributionAllowed',
        globalMaximumContributionAllowed,
        { from: this.root }
      );

      await expectRevert(
        this.rewardsInstance.createReward(rewardCost, 86400, 10, true, {
          from: this.campaignOwner,
        }),
        'amount too high'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                                modifyReward                                */
    /* -------------------------------------------------------------------------- */
    it('should modify a reward', async function () {
      await this.rewardsInstance.createReward(500, 86400, 10, true, {
        from: this.campaignOwner,
      });
      const receipt = await this.rewardsInstance.modifyReward(
        0,
        200,
        86400,
        3,
        false,
        {
          from: this.campaignOwner,
        }
      );
      expect(
        (await this.rewardsInstance.rewards(0)).value
      ).to.be.bignumber.equal(new BN('200'));
      expect(
        (await this.rewardsInstance.rewards(0)).deliveryDate
      ).to.be.bignumber.equal(new BN('86400'));
      expect(
        (await this.rewardsInstance.rewards(0)).stock
      ).to.be.bignumber.equal(new BN('3'));
      expect((await this.rewardsInstance.rewards(0)).active).to.be.equal(false);

      expectEvent(receipt, 'RewardModified', {
        rewardId: new BN('0'),
        campaignId: new BN(this.campaignID),
        value: new BN('200'),
        deliveryDate: new BN('86400'),
        stock: new BN('3'),
        active: false,
        sender: this.campaignOwner,
      });
    });
    it('should increase reward stock count', async function () {
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      const receipt = await this.rewardsInstance.increaseRewardStock(0, 1, {
        from: this.campaignOwner,
      });
      expect(
        (await this.rewardsInstance.rewards(0)).stock
      ).to.be.bignumber.equal(new BN('4'));
      expectEvent(receipt, 'RewardStockIncreased', {
        rewardId: new BN('0'),
        campaignId: new BN(this.campaignID),
        count: new BN('1'),
        sender: this.campaignOwner,
      });
    });
    it('reward modification should fail if it has backers', async function () {
      await this.approvedCampaignSetup({
        duration: 86400,
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 600,
      });
      await expectRevert(
        this.rewardsInstance.modifyReward(0, 200, 86400, 3, false, {
          from: this.campaignOwner,
        }),
        'has backers'
      );
    });
    it("reward modification should fail if the reward doesn't exist", async function () {
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.rewardsInstance.destroyReward(0, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.rewardsInstance.modifyReward(0, 200, 86400, 3, false, {
          from: this.campaignOwner,
        }),
        'not found'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                                destroyReward                               */
    /* -------------------------------------------------------------------------- */
    it('should delete a reward', async function () {
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      const receipt = await this.rewardsInstance.destroyReward(0, {
        from: this.campaignOwner,
      });

      expect(
        (await this.rewardsInstance.rewards(0)).value
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        (await this.rewardsInstance.rewards(0)).deliveryDate
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        (await this.rewardsInstance.rewards(0)).stock
      ).to.be.bignumber.equal(new BN('0'));
      expect((await this.rewardsInstance.rewards(0)).active).to.be.equal(false);

      expectEvent(receipt, 'RewardDestroyed', {
        rewardId: new BN('0'),
        campaignId: new BN(this.campaignID),
        sender: this.campaignOwner,
      });
    });
    it('reward deletion should fail if the reward has backers', async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 600,
      });
      await expectRevert(
        this.rewardsInstance.destroyReward(0, { from: this.campaignOwner }),
        'has backers'
      );
    });
    it("reward deletion should fail if the reward doesn't exist", async function () {
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.rewardsInstance.destroyReward(0, { from: this.campaignOwner });
      await expectRevert(
        this.rewardsInstance.destroyReward(0, { from: this.campaignOwner }),
        'not found'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                             campaignSentReward                             */
    /* -------------------------------------------------------------------------- */
    it('should mark a reward as delivered', async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 600,
      });
      const receipt = await this.rewardsInstance.campaignSentReward(0, true, {
        from: this.campaignOwner,
      });

      expect(
        (await this.rewardsInstance.rewardRecipients(0))
          .deliveryConfirmedByCampaign
      ).to.be.equal(true);
      expectEvent(receipt, 'RewarderApproval', {
        rewardRecipientId: new BN('0'),
        campaignId: new BN(this.campaignID),
        status: true,
        sender: this.campaignOwner,
      });
    });
    it('reward delivery update should fail if not called by the campaign owner', async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 600,
      });
      await expectRevert(
        this.rewardsInstance.campaignSentReward(0, true, {
          from: this.addr1,
        }),
        'admin or factory'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                         userReceivedCampaignReward                         */
    /* -------------------------------------------------------------------------- */
    it('should mark a reward as received', async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 600,
      });
      await this.rewardsInstance.campaignSentReward(0, true, {
        from: this.campaignOwner,
      });
      const receipt = await this.rewardsInstance.userReceivedCampaignReward(0, {
        from: this.root,
      });

      expect(
        (await this.rewardsInstance.rewardRecipients(0)).deliveryConfirmedByUser
      ).to.be.equal(true);
      expectEvent(receipt, 'RewardRecipientApproval', {
        rewardRecipientId: new BN('0'),
        campaignId: new BN(this.campaignID),
        sender: this.root,
      });
    });
    it('reward received should fail if reward delivery is marked false', async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 600,
      });
      await expectRevert(
        this.rewardsInstance.userReceivedCampaignReward(0, {
          from: this.root,
        }),
        'reward not delivered yet'
      );
    });
    it("reward received should fail if user isn't the owner of the reward", async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(1000, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 600,
      });
      await this.campaignInstance.contribute(this.testToken.address, 1, true, {
        from: this.addr1,
        value: 1000,
      });
      await this.rewardsInstance.campaignSentReward(0, true, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.rewardsInstance.userReceivedCampaignReward(0, {
          from: this.addr1,
        }),
        'not owner of reward'
      );
    });
    it("reward received should fail if the user isn't an approver", async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 600,
      });
      await this.rewardsInstance.campaignSentReward(0, true, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.rewardsInstance.userReceivedCampaignReward(0, {
          from: this.addr1,
        }),
        'not an approver'
      );
    });
    it('should revert if called directly', async function () {
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.rewardsInstance.assignReward(0, 500, this.addr1, {
          from: this.campaignOwner,
        }),
        'forbidden'
      );
      await expectRevert(
        this.rewardsInstance.renounceRewards(this.addr1),
        'forbidden'
      );
      await expectRevert(
        this.rewardsInstance.transferRewards(this.addr1, this.root),
        'forbidden'
      );
    });
  }
);
