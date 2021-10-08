export {};
const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

// compiled artifacts
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
  'Campaign',
  function ([
    campaignOwner,
    root,
    factoryWallet,
    addr1,
    addr2,
    addr3,
    addr4,
    addr5,
  ]) {
    beforeEach(async function () {
      this.root = root;
      this.campaignOwner = campaignOwner;
      this.factoryWallet = factoryWallet;
      this.addr1 = addr1;
      this.addr2 = addr2;
      this.addr3 = addr3;
      this.addr4 = addr4;
      this.addr5 = addr5;
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
        reportThresholdMark: 80,
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
      await this.factory.signUp({
        from: this.addr2,
      });
      await this.factory.signUp({
        from: this.addr3,
      });
      await this.factory.signUp({
        from: this.addr4,
      });
      await this.factory.toggleUserApproval(0, true, { from: this.root });
      await this.factory.toggleUserApproval(1, true, { from: this.root });
      await this.factory.toggleUserApproval(2, true, { from: this.root });
      await this.factory.toggleUserApproval(3, true, { from: this.root });
      await this.factory.toggleUserApproval(4, true, { from: this.root });
      await this.factory.toggleUserApproval(5, true, { from: this.root });
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
        { from: this.addr2 }
      );
      await this.testToken.transfer(this.addr2, 100000, {
        from: this.root,
      });
      await this.testToken.increaseAllowance(
        this.campaignInstance.address,
        100000,
        { from: this.addr3 }
      );
      await this.testToken.transfer(this.addr3, 100000, {
        from: this.root,
      });
      await this.testToken.increaseAllowance(
        this.campaignInstance.address,
        100000,
        { from: this.addr4 }
      );
      await this.testToken.transfer(this.addr4, 100000, {
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

    it('deployer owns the campaign', async function () {
      assert.equal(await this.campaignInstance.root(), this.campaignOwner);
    });

    it('campaign is paused on initialization', async function () {
      assert.equal(await this.campaignInstance.paused(), true);
    });

    /* -------------------------------------------------------------------------- */
    /*                          transferCampaignOwnership                         */
    /* -------------------------------------------------------------------------- */
    it('should transfer campaign ownership to a new address', async function () {
      await this.campaignInstance.unpauseCampaign({ from: this.root });
      const receipt = await this.campaignInstance.transferCampaignOwnership(
        this.addr1,
        {
          from: this.campaignOwner,
        }
      );
      const DEFAULT_ADMIN_ROLE =
        await this.campaignInstance.DEFAULT_ADMIN_ROLE();
      expect(
        await this.campaignInstance.hasRole(
          DEFAULT_ADMIN_ROLE,
          this.campaignOwner
        )
      ).to.be.equal(false);
      expect(
        await this.campaignInstance.hasRole(DEFAULT_ADMIN_ROLE, this.addr1)
      ).to.be.equal(true);
      expect(await this.campaignInstance.root()).to.be.equal(this.addr1);
      expectEvent(receipt, 'CampaignOwnershipTransferred', {
        campaignId: new BN(this.campaignID),
        newUser: this.addr1,
        sender: this.campaignOwner,
      });
    });
    it('campaign ownership transfer should fail if the new address is unverified', async function () {
      await this.campaignInstance.unpauseCampaign({ from: this.root });
      await this.factory.toggleUserApproval(2, false, { from: this.root });
      await expectRevert(
        this.campaignInstance.transferCampaignOwnership(this.addr1, {
          from: this.campaignOwner,
        }),
        'unverified'
      );
    });
    it('campaign ownership transfer should fail if the new address does not exist', async function () {
      await this.campaignInstance.unpauseCampaign({ from: this.root });
      await expectRevert(
        this.campaignInstance.transferCampaignOwnership(this.addr5, {
          from: this.campaignOwner,
        }),
        'user does not exist'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                          transferCampaignUserData                          */
    /* -------------------------------------------------------------------------- */
    it('should transfer a users data in a campaign to a new address', async function () {
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
      const receipt = await this.campaignInstance.transferCampaignUserData(
        this.root,
        this.addr1,
        { from: this.root }
      );
      expect(
        await this.campaignInstance.userTotalContribution(this.root)
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.campaignInstance.userTotalContribution(this.addr1)
      ).to.be.bignumber.equal(new BN('600'));
      expect(await this.campaignInstance.approvers(this.root)).to.be.equal(
        false
      );
      expect(await this.campaignInstance.approvers(this.addr1)).to.be.equal(
        true
      );
      expect(
        await this.rewardsInstance.userRewardCount(this.root)
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.rewardsInstance.userRewardCount(this.addr1)
      ).to.be.bignumber.equal(new BN('1'));
      expect((await this.rewardsInstance.rewardRecipients(0)).user).to.be.equal(
        this.addr1
      );
      expectEvent(receipt, 'CampaignUserDataTransferred', {
        campaignId: new BN(this.campaignID),
        oldAddress: this.root,
        newAddress: this.addr1,
        sender: this.root,
      });
    });
    it('transfer of user data in campaign should fail if the new address is unverified', async function () {
      await this.factory.toggleUserApproval(2, false, { from: this.root });
      await this.approvedCampaignSetup({
        duration: 86400,
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: 600,
      });
      await expectRevert(
        this.campaignInstance.transferCampaignUserData(this.root, this.addr1, {
          from: this.root,
        }),
        'unverified'
      );
    });
    it('transfer of user data in campaign should fail if the old address is not an approver', async function () {
      await this.approvedCampaignSetup({
        duration: 86400,
        from: this.campaignOwner,
      });
      await expectRevert.unspecified(
        this.campaignInstance.transferCampaignUserData(this.root, this.addr1, {
          from: this.root,
        })
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                             setCampaignSettings                            */
    /* -------------------------------------------------------------------------- */
    it('campaign owner can set campaign settings', async function () {
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
      const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

      expect(await this.campaignInstance.target()).to.be.bignumber.equal(
        new BN('20000')
      );
      expect(
        await this.campaignInstance.minimumContribution()
      ).to.be.bignumber.equal(new BN('1'));
      expect(await this.campaignInstance.deadline()).to.be.bignumber.equal(
        new BN(`${+block.timestamp + 604800}`)
      );
      expect(
        await this.campaignInstance.deadlineSetTimes()
      ).to.be.bignumber.equal(new BN('0'));
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
        sender: this.campaignOwner,
      });
    });
    it('campaign settings modification should work for factory even if campaign has been approved', async function () {
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
    it('campaign settings modification should fail if campaign has been approved', async function () {
      this.factory.toggleCampaignApproval(this.campaignID, true, {
        from: this.root,
      });
      this.factory.toggleCampaignActive(this.campaignID, true, {
        from: this.root,
      });
      await expectRevert(
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
        ),
        'approved'
      );
    });
    it('campaign settings modification should fail if the token has not being approved', async function () {
      await this.factory.toggleAcceptedToken(this.testToken.address, false, {
        from: this.root,
      });
      await expectRevert(
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
        ),
        'invalid token'
      );
    });
    it('campaign settings modification should fail if minimum contribution is larger than maximum or less than minimum allowed from factory', async function () {
      await this.factory.setCampaignTransactionConfig(
        'minimumContributionAllowed',
        2,
        {
          from: this.root,
        }
      );
      await expectRevert(
        this.campaignInstance.setCampaignSettings(
          20000,
          1,
          604800,
          1,
          this.testToken.address,
          false,
          {
            from: this.campaignOwner,
          }
        ),
        'contribution deficit'
      );
      await expectRevert(
        this.campaignInstance.setCampaignSettings(
          20000,
          300000,
          604800,
          1,
          this.testToken.address,
          false,
          {
            from: this.campaignOwner,
          }
        ),
        'contribution deficit'
      );
    });
    it('campaign settings modification should fail if target is larger than maximum or less than minimum allowed from factory', async function () {
      await this.factory.setCampaignTransactionConfig(
        'minimumCampaignTarget',
        100,
        {
          from: this.root,
        }
      );
      await this.factory.setCampaignTransactionConfig(
        'maximumCampaignTarget',
        1000,
        {
          from: this.root,
        }
      );
      await expectRevert(
        this.campaignInstance.setCampaignSettings(
          90,
          1,
          604800,
          1,
          this.testToken.address,
          false,
          {
            from: this.campaignOwner,
          }
        ),
        'target deficit'
      );
      await expectRevert(
        this.campaignInstance.setCampaignSettings(
          200000,
          100000,
          604800,
          1,
          this.testToken.address,
          false,
          {
            from: this.campaignOwner,
          }
        ),
        'target deficit'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                               extendDeadline                               */
    /* -------------------------------------------------------------------------- */
    it('should extend the campaign duration', async function () {
      await this.approvedCampaignSetup({
        duration: 2,
        from: this.campaignOwner,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      const receipt = await this.campaignInstance.extendDeadline(86400, {
        from: this.campaignOwner,
      });
      const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

      expect(await this.campaignInstance.deadline()).to.be.bignumber.equal(
        new BN(`${+block.timestamp + 86400}`)
      );
      expect(
        await this.campaignInstance.deadlineSetTimes()
      ).to.be.bignumber.equal(new BN('1'));
      expectEvent(receipt, 'CampaignDeadlineExtended', {
        campaignId: new BN('0'),
        time: new BN('86400'),
        sender: this.campaignOwner,
      });
    });
    it("duration extension should fail if the campaign isn't active or enabled", async function () {
      await this.approvedCampaignSetup({
        duration: 2,
        from: this.campaignOwner,
        approveCampaign: false,
        activateCampaign: false,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await expectRevert.unspecified(
        this.campaignInstance.extendDeadline(86400, {
          from: this.campaignOwner,
        })
      );
    });
    it("duration extension should fail if the campaign duration hasn't expired", async function () {
      await this.approvedCampaignSetup({
        duration: 86400,
        from: this.campaignOwner,
      });
      await expectRevert.unspecified(
        this.campaignInstance.extendDeadline(86400, {
          from: this.campaignOwner,
        })
      );
    });
    it('duration extension should fail if ability to extend has been exhausted', async function () {
      await this.factory.setCampaignTransactionConfig(
        'deadlineStrikesAllowed',
        1,
        { from: this.root }
      );
      await this.factory.setCampaignTransactionConfig(
        'minDeadlineExtension',
        1,
        {
          from: this.root,
        }
      );
      await this.approvedCampaignSetup({
        duration: 3,
        from: this.campaignOwner,
      });
      await new Promise((resolve) => setTimeout(resolve, 4000));
      await this.campaignInstance.extendDeadline(3, {
        from: this.campaignOwner,
      });
      await new Promise((resolve) => setTimeout(resolve, 4000));
      expect(
        await this.campaignInstance.deadlineSetTimes()
      ).to.be.bignumber.equal(new BN('1'));
      await expectRevert(
        this.campaignInstance.extendDeadline(86400, {
          from: this.campaignOwner,
        }),
        'exhausted deadline strikes'
      );
    });
    it('duration extension should fail if the time to extend by is less or greater than allowed from factory', async function () {
      await this.approvedCampaignSetup({
        duration: 3,
        from: this.campaignOwner,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await expectRevert.unspecified(
        this.campaignInstance.extendDeadline(604801, {
          from: this.campaignOwner,
        })
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                             setDeadlineSetTimes                            */
    /* -------------------------------------------------------------------------- */
    it('should set the number of times a campaign manager has extended deadline', async function () {
      await this.approvedCampaignSetup({
        duration: 86400,
        from: this.campaignOwner,
      });
      await this.campaignInstance.setDeadlineSetTimes(2, { from: this.root });
      expect(
        await this.campaignInstance.deadlineSetTimes()
      ).to.be.bignumber.equal(new BN('2'));
    });
    it('should fail if the ability to extend campaign duration is called by the campaign owner', async function () {
      await this.approvedCampaignSetup({
        duration: 86400,
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.setDeadlineSetTimes(30, {
          from: this.campaignOwner,
        }),
        'only factory'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                                 contribute                                 */
    /* -------------------------------------------------------------------------- */
    it('should contribute into the campaign and make user an approver', async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      const receipt = await this.campaignInstance.contribute(
        this.testToken.address,
        0,
        false,
        {
          from: this.root,
          value: 600,
        }
      );

      expect(await this.campaignInstance.approvers(this.root)).to.be.equal(
        true
      );
      expect(
        await this.campaignInstance.approversCount()
      ).to.be.bignumber.equal(new BN('1'));
      expect(
        await this.campaignInstance.totalCampaignContribution()
      ).to.be.bignumber.equal(new BN('600'));
      expect(
        await this.campaignInstance.userTotalContribution(this.root)
      ).to.be.bignumber.equal(new BN('600'));
      expectEvent(receipt, 'ContributionMade', {
        campaignId: new BN(this.campaignID),
        amount: new BN('600'),
        rewardId: new BN('0'),
        withReward: false,
        sender: this.root,
      });
    });
    it('should emit an event and set campaign state set to live when the campagin target is met', async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        target: 5000,
        from: this.campaignOwner,
      });
      const receipt = await this.campaignInstance.contribute(
        this.testToken.address,
        0,
        false,
        {
          from: this.root,
          value: 5000,
        }
      );
      // check campaign state
      // where 2 is LIVE
      expect(
        (await this.campaignInstance.campaignState()).toString()
      ).to.be.equal('2');
      expectEvent(receipt, 'TargetMet', {
        campaignId: new BN(this.campaignID),
        amount: new BN('5000'),
      });
    });
    it('contribution should fail if contributor is campaign owner', async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.contribute(this.testToken.address, 0, false, {
          from: this.campaignOwner,
          value: 600,
        }),
        'root owner'
      );
    });
    it("should fail if token used for contribution isn't accepted", async function () {
      await this.approvedCampaignSetup({
        duration: 184000,
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.contribute(
          '0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b',
          0,
          false,
          {
            from: this.root,
            value: 5000,
          }
        ),
        'invalid token'
      );
    });
    it('should fail if contribution amount is below minimum or above maximum', async function () {
      let config: CampaignSetupConfig = {
        duration: 184000,
        minimumContribution: 10,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await expectRevert(
        this.campaignInstance.contribute(this.testToken.address, 0, false, {
          from: this.root,
          value: 1,
        }),
        'value too low'
      );
      await expectRevert(
        this.campaignInstance.contribute(this.testToken.address, 0, false, {
          from: this.root,
          value: 1000000,
        }),
        'value too high'
      );
    });
    it('contribution should fail if campaign does not allow contribution after target is met', async function () {
      let config: CampaignSetupConfig = {
        duration: 184000,
        target: 6000,
        minimumContribution: 10,
        allowContributionAfterTargetIsMet: false,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await expectRevert(
        this.campaignInstance.contribute(this.testToken.address, 0, false, {
          from: this.root,
          value: 7000,
        }),
        'exceeds target'
      );
    });
    it('should mark a contributor as eligible for a reward', async function () {
      let config: CampaignSetupConfig = {
        duration: 184000,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      const receipt = await this.campaignInstance.contribute(
        this.testToken.address,
        0,
        true,
        {
          from: this.root,
          value: 1000,
        }
      );

      expect(
        (await this.rewardsInstance.rewardRecipients(0)).rewardId
      ).to.be.bignumber.equal(new BN('0'));
      expect((await this.rewardsInstance.rewardRecipients(0)).user).to.be.equal(
        this.root
      );
      expect(
        (await this.rewardsInstance.rewardRecipients(0))
          .deliveryConfirmedByCampaign
      ).to.be.equal(false);
      expect(
        (await this.rewardsInstance.rewardRecipients(0)).deliveryConfirmedByUser
      ).to.be.equal(false);
      expect(
        await this.rewardsInstance.userRewardCount(this.root)
      ).to.be.bignumber.equal(new BN('1'));
      expect(
        await this.rewardsInstance.rewardToRewardRecipientCount(0)
      ).to.be.bignumber.equal(new BN('1'));
      expectEvent(receipt, 'ContributionMade', {
        campaignId: new BN(this.campaignID),
        amount: new BN('1000'),
        rewardId: new BN('0'),
        withReward: true,
        sender: this.root,
      });
    });

    /* -------------------------------------------------------------------------- */
    /*                           withdrawOwnContribution                          */
    /* -------------------------------------------------------------------------- */
    it('should withdraw user contribution and remove the user as a contributor', async function () {
      let config: CampaignSetupConfig = {
        duration: 184000,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.rewardsInstance.createReward(500, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.rewardsInstance.createReward(700, 86400, 3, true, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, true, {
        from: this.root,
        value: 1000,
      });
      await this.campaignInstance.contribute(this.testToken.address, 1, true, {
        from: this.root,
        value: 700,
      });
      const receipt = await this.campaignInstance.withdrawOwnContribution(
        this.root,
        {
          from: this.root,
        }
      );

      expect(await this.campaignInstance.approvers(this.root)).to.be.equal(
        false
      );
      expect(
        await this.campaignInstance.approversCount()
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.rewardsInstance.userRewardCount(this.root)
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.rewardsInstance.rewardToRewardRecipientCount(0)
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.rewardsInstance.rewardToRewardRecipientCount(1)
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.campaignInstance.userTotalContribution(this.root)
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.campaignInstance.totalCampaignContribution()
      ).to.be.bignumber.equal(new BN('0'));

      expectEvent(receipt, 'ContributionWithdrawn', {
        campaignId: new BN(this.campaignID),
        amount: new BN('1700'),
        sender: this.root,
      });
    });
    it('should withdraw user contribution if the campaign state is in review mode and there are left over funds', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        target: 7114,
        from: this.campaignOwner,
      };
      let rootContribution = 5379,
        addr1Contribution = 1735,
        requestAmount = 3956;

      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: rootContribution,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: addr1Contribution,
      });
      await this.campaignInstance.createRequest(
        this.addr3,
        requestAmount,
        86400,
        {
          from: this.campaignOwner,
        }
      );
      await this.campaignInstance.voteOnRequest(0, 1, { from: this.root });
      await this.campaignInstance.voteOnRequest(0, 1, { from: this.addr1 });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.reviewMode({ from: this.campaignOwner });

      let rootLoss = await this.campaignInstance.userContributionLoss(
        this.root
      );
      let addr1Loss = await this.campaignInstance.userContributionLoss(
        this.addr1
      );
      let rootTotalContribution =
        await this.campaignInstance.userTotalContribution(this.root);
      let addr1TotalContribution =
        await this.campaignInstance.userTotalContribution(this.addr1);

      const receipt1 = await this.campaignInstance.withdrawOwnContribution(
        this.root,
        {
          from: this.root,
        }
      );
      const receipt2 = await this.campaignInstance.withdrawOwnContribution(
        this.addr1,
        {
          from: this.addr1,
        }
      );

      const amountWithdrawnByRoot = rootTotalContribution - rootLoss,
        amountWithdrawnByAddr1 = addr1TotalContribution - addr1Loss;

      expect(
        await this.campaignInstance.userTotalContribution(this.root)
      ).to.be.bignumber.equal(
        new BN(`${rootTotalContribution - amountWithdrawnByRoot}`)
      );
      expect(
        await this.campaignInstance.userTotalContribution(this.addr1)
      ).to.be.bignumber.equal(
        new BN(`${addr1TotalContribution - amountWithdrawnByAddr1}`)
      );
      expect(
        await this.campaignInstance.campaignBalance()
      ).to.be.bignumber.equal(
        new BN(rootContribution + addr1Contribution - requestAmount)
      );
      expectEvent(receipt1, 'ContributionWithdrawn', {
        campaignId: new BN(this.campaignID),
        amount: new BN(rootTotalContribution - rootLoss),
        sender: this.root,
      });
      expectEvent(receipt2, 'ContributionWithdrawn', {
        campaignId: new BN(this.campaignID),
        amount: new BN(addr1TotalContribution - addr1Loss),
        sender: this.addr1,
      });
    });
    it('contribution withdrawal should fail if user is not an approver', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
      };

      await this.approvedCampaignSetup(config);
      await expectRevert(
        this.campaignInstance.withdrawOwnContribution(this.root, {
          from: this.root,
        }),
        'non approver'
      );
    });
    it('contribution withdrawal should fail if campaign is not in collection stage', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
        target: 5000,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: 5000,
      });
      await expectRevert(
        this.campaignInstance.withdrawOwnContribution(this.root, {
          from: this.root,
        }),
        'campaign no longer in collection stage'
      );
    });
    it('contribution withdrawal should fail if requests have been finalized', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
        target: 5000,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 4000,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await this.campaignInstance.createRequest(this.addr3, 1133, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, { from: this.addr1 });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.withdrawOwnContribution(this.root, {
          from: this.addr1,
        }),
        'requests have been finalized'
      );
    });
    it('contribution withdrawal should fail if withdrawals are paused', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
        target: 5000,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 500,
      });
      await this.campaignInstance.toggleWithdrawalState(true, {
        from: this.root,
      });
      await expectRevert.unspecified(
        this.campaignInstance.withdrawOwnContribution(this.root, {
          from: this.addr1,
        })
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                         withdrawContributionForUser                        */
    /* -------------------------------------------------------------------------- */
    it('should withdraw contribution on behalf of a user', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 1000,
      });
      const receipt = await this.campaignInstance.withdrawContributionForUser(
        this.addr1,
        this.addr1,
        { from: this.root }
      );

      expect(await this.campaignInstance.approvers(this.addr1)).to.be.equal(
        false
      );
      expect(
        await this.campaignInstance.approversCount()
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.campaignInstance.userTotalContribution(this.addr1)
      ).to.be.bignumber.equal(new BN('0'));
      expect(
        await this.campaignInstance.totalCampaignContribution()
      ).to.be.bignumber.equal(new BN('0'));

      expectEvent(receipt, 'ContributionWithdrawn', {
        campaignId: new BN(this.campaignID),
        amount: new BN('1000'),
        user: this.addr1,
        sender: this.root,
      });
    });

    it('contribution withdrawal on behalf of a user should fail if not called by factory', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 1000,
      });
      await expectRevert(
        this.campaignInstance.withdrawContributionForUser(
          this.addr1,
          this.addr1,
          { from: this.addr1 }
        ),
        'only factory'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                                createRequest                               */
    /* -------------------------------------------------------------------------- */
    it('should create a spending request', async function () {
      let config: CampaignSetupConfig = {
        duration: 4,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 1000,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      const receipt = await this.campaignInstance.createRequest(
        this.addr3,
        1000,
        86400,
        {
          from: this.campaignOwner,
        }
      );
      const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

      const request = await this.campaignInstance.requests(0);
      expect(request.recipient).to.be.equal(this.addr3);
      expect(request.complete).to.be.equal(false);
      expect(request.value).to.be.bignumber.equal(new BN('1000'));
      expect(request.approvalCount).to.be.bignumber.equal(new BN('0'));
      expect(request.duration).to.be.bignumber.equal(
        new BN(`${+block.timestamp + 86400}`)
      );
      expect(request.void).to.be.equal(false);
      expect(await this.campaignInstance.requestCount()).to.be.bignumber.equal(
        new BN('1')
      );
      expect(
        await this.campaignInstance.currentRunningRequest()
      ).to.be.bignumber.equal(new BN('0'));
      expectEvent(receipt, 'RequestAdded', {
        requestId: new BN('0'),
        campaignId: new BN(this.campaignID),
        duration: new BN('86400'),
        value: new BN('1000'),
        recipient: this.addr3,
        sender: this.campaignOwner,
      });
    });
    it("should create a request if deadline hasn't expired expired but target is met", async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 1000, 86400, {
        from: this.campaignOwner,
      });
      expect(await this.campaignInstance.requestCount()).to.be.bignumber.equal(
        new BN('1')
      );
    });
    it('spending request creation should fail if campaign deadline has not expired', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 1000,
      });
      await expectRevert(
        this.campaignInstance.createRequest(this.addr3, 1000, 86400, {
          from: this.campaignOwner,
        }),
        'deadline not expired'
      );
    });
    it('spending request creation should fail if goal is fixed and target is not met', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
        goalType: 0,
        target: 5000,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 1000,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await expectRevert(
        this.campaignInstance.createRequest(this.addr3, 1000, 86400, {
          from: this.campaignOwner,
        }),
        'target not met'
      );
    });
    it('spending request creation should fail if amount is above total contribution balance', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
        goalType: 0,
        target: 5000,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 5000,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await expectRevert(
        this.campaignInstance.createRequest(this.addr3, 6000, 86400, {
          from: this.campaignOwner,
        }),
        'request amount cannot be higher than campaign balance'
      );
    });
    it('spending request creation should fail if amount is below minimum or above maximum request amount', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
        target: 20000,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 5000,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await expectRevert(
        this.campaignInstance.createRequest(this.addr3, 400, 86400, {
          from: this.campaignOwner,
        }),
        'amount deficit'
      );
      await expectRevert(
        this.campaignInstance.createRequest(this.addr3, 11000, 86400, {
          from: this.campaignOwner,
        }),
        'amount deficit'
      );
    });
    it('spending request creation should fail if duration is below minimum or above maximum request duration', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 1000,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await expectRevert(
        this.campaignInstance.createRequest(this.addr3, 500, 80, {
          from: this.campaignOwner,
        }),
        'duration deficit'
      );
      await expectRevert(
        this.campaignInstance.createRequest(this.addr3, 500, 88886400, {
          from: this.campaignOwner,
        }),
        'duration deficit'
      );
    });
    it('spending request creation should fail if previous request is still running', async function () {
      let config: CampaignSetupConfig = {
        duration: 2,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 1000,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.createRequest(this.addr3, 500, 86400, {
          from: this.campaignOwner,
        }),
        'request ongoing'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                                 voidRequest                                */
    /* -------------------------------------------------------------------------- */
    it('should void a spending request', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      const receipt = await this.campaignInstance.voidRequest(0, {
        from: this.campaignOwner,
      });
      const request = await this.campaignInstance.requests(0);

      expect(request.void).to.be.equal(true);
      expectEvent(receipt, 'RequestVoided', {
        requestId: new BN('0'),
        campaignId: new BN(this.campaignID),
        sender: this.campaignOwner,
      });
    });
    it('voiding a spending request should fail if the request was previously voided', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voidRequest(0, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.voidRequest(0, { from: this.campaignOwner }),
        'voided'
      );
    });
    it('voiding a spending request should fail if the request has already been voted on', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, { from: this.addr1 });
      await expectRevert(
        this.campaignInstance.voidRequest(0, { from: this.campaignOwner }),
        'has approvals'
      );
    });
    it('voiding a spending request should fail if not called by campaign owner or factory', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.voidRequest(0, {
          from: this.addr1,
        }),
        'admin or factory'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                                voteOnRequest                               */
    /* -------------------------------------------------------------------------- */
    it('should vote on a spending request', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      const receipt = await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });

      expect(await this.campaignInstance.hasVoted(0, this.addr1)).to.be.equal(
        true
      );
      expect(
        (await this.campaignInstance.requests(0)).approvalCount
      ).to.be.bignumber.equal(new BN('1'));
      expectEvent(receipt, 'Voted', {
        requestId: new BN('0'),
        support: new BN('1'),
        campaignId: new BN(this.campaignID),
        sender: this.addr1,
      });
    });
    it('voting on a spending request should fail if already voted', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 2, {
        from: this.addr1,
      });
      await expectRevert(
        this.campaignInstance.voteOnRequest(0, 1, {
          from: this.addr1,
        }),
        'voted'
      );
    });
    it('voting on a spending request should fail if the request is expired', async function () {
      await this.factory.setCampaignTransactionConfig('minRequestDuration', 2, {
        from: this.root,
      });
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 2, {
        from: this.campaignOwner,
      });
      await new Promise((resolve) => setTimeout(resolve, 3000));
      await expectRevert(
        this.campaignInstance.voteOnRequest(0, 1, {
          from: this.addr1,
        }),
        'request expired'
      );
    });
    it('voting on a spending request should fail if the request is void', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voidRequest(0, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.voteOnRequest(0, 0, {
          from: this.addr1,
        }),
        'voided'
      );
    });
    it('voting on a spending request should fail if the user is not an approver', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.voteOnRequest(0, 1, {
          from: this.addr1,
        }),
        'non approver'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                                 cancelVote                                 */
    /* -------------------------------------------------------------------------- */
    it('should cancel a vote on a spending request', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      const receipt = await this.campaignInstance.cancelVote(0, {
        from: this.addr1,
      });

      expect(await this.campaignInstance.hasVoted(0, this.addr1)).to.be.equal(
        false
      );
      expect(
        (await this.campaignInstance.requests(0)).approvalCount
      ).to.be.bignumber.equal(new BN('0'));
      expectEvent(receipt, 'VoteCancelled', {
        requestId: new BN('0'),
        support: new BN('1'),
        campaignId: new BN(this.campaignID),
        sender: this.addr1,
      });
    });
    it('vote cancellation should fail if the user did not vote before', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.cancelVote(0, {
          from: this.addr1,
        }),
        'vote first'
      );
    });
    it('vote cancellation should fail if the user is not an approver', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.cancelVote(0, {
          from: this.addr1,
        }),
        'non approver'
      );
    });
    it('vote cancellation should fail if the request has expired', async function () {
      await this.factory.setCampaignTransactionConfig('minRequestDuration', 2, {
        from: this.root,
      });
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 4, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await new Promise((resolve) => setTimeout(resolve, 5000));
      await expectRevert(
        this.campaignInstance.cancelVote(0, { from: this.addr1 }),
        'request expired'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                               finalizeRequest                              */
    /* -------------------------------------------------------------------------- */
    it('should finalize a request', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 7000,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr2,
        value: 7000,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr3,
        value: 7000,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr4,
        value: 7000,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: 7000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr2,
      });
      await this.campaignInstance.voteOnRequest(0, 2, {
        from: this.addr3,
      });
      await this.campaignInstance.voteOnRequest(0, 0, {
        from: this.root,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr4,
      });

      const receipt = await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      const request = await this.campaignInstance.requests(0);

      expect(request.approvalCount).to.be.bignumber.equal(new BN('3'));
      expect(request.abstainedCount).to.be.bignumber.equal(new BN('1'));
      expect(request.againstCount).to.be.bignumber.equal(new BN('1'));
      expect(request.complete).to.be.equal(true);
      expect(
        await this.campaignInstance.finalizedRequestCount()
      ).to.be.bignumber.equal(new BN('1'));
      expect(
        await this.campaignInstance.campaignBalance()
      ).to.be.bignumber.equal(new BN('34500'));
      expect(
        await this.campaignInstance.totalCampaignContribution()
      ).to.be.bignumber.equal(new BN('35000'));
      expectEvent(receipt, 'RequestComplete', {
        requestId: new BN('0'),
        campaignId: new BN(this.campaignID),
        sender: this.campaignOwner,
      });
    });
    it("request finalization should fail if approval count isn't enough", async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });

      await expectRevert(
        this.campaignInstance.finalizeRequest(0, {
          from: this.campaignOwner,
        }),
        'approval deficit'
      );
    });
    it('request finalization should fail if the request was finalized', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });

      await expectRevert(
        this.campaignInstance.finalizeRequest(0, { from: this.campaignOwner }),
        'finalized'
      );
    });
    it('request finalization should fail if votes against are more than votes in-favor', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr2,
        value: 20000,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 0, {
        from: this.addr1,
      });
      await this.campaignInstance.voteOnRequest(0, 0, {
        from: this.addr2,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.root,
      });
      await expectRevert(
        this.campaignInstance.finalizeRequest(0, {
          from: this.campaignOwner,
        }),
        'approval deficit'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                                 reviewMode                                 */
    /* -------------------------------------------------------------------------- */
    it('should set a campaign for review', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      const receipt = await this.campaignInstance.reviewMode({
        from: this.campaignOwner,
      });

      expect(
        (await this.campaignInstance.campaignState()).toString()
      ).to.be.equal('3');
      expect(await this.campaignInstance.paused()).to.be.equal(true);
      expectEvent(receipt, 'CampaignStateChange', {
        campaignId: new BN(this.campaignID),
        state: new BN('3'),
        sender: this.campaignOwner,
      });
    });
    it('setting a campaign in review mode should fail if there are no requests made', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await expectRevert(
        this.campaignInstance.reviewMode({ from: this.campaignOwner }),
        'no finalized requests'
      );
    });
    it('setting a campaign in review mode should fail if there is a request still running', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.reviewMode({ from: this.campaignOwner }),
        'request ongoing'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                          reviewCampaignPerformance                         */
    /* -------------------------------------------------------------------------- */
    it('should review the campaign performance', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.reviewMode({ from: this.campaignOwner });

      const receipt = await this.campaignInstance.reviewCampaignPerformance({
        from: this.addr1,
      });

      expect(await this.campaignInstance.reviewed(this.addr1)).to.be.equal(
        true
      );
      expect(await this.campaignInstance.reviewCount()).to.be.bignumber.equal(
        new BN('1')
      );
      expectEvent(receipt, 'CampaignReviewed', {
        campaignId: new BN(this.campaignID),
        sender: this.addr1,
      });
    });
    it('performance review should fail if campaign state is not in review', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.pauseCampaign({ from: this.root });

      await expectRevert(
        this.campaignInstance.reviewCampaignPerformance({
          from: this.addr1,
        }),
        'not in review'
      );
    });
    it('performance review should fail if the user reviewed previously', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.reviewMode({ from: this.campaignOwner });

      await this.campaignInstance.reviewCampaignPerformance({
        from: this.addr1,
      });
      await expectRevert(
        this.campaignInstance.reviewCampaignPerformance({
          from: this.addr1,
        }),
        'reviewed'
      );
    });
    it('performance review should fail if the user is not an approver', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.root,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.reviewMode({ from: this.campaignOwner });

      await expectRevert(
        this.campaignInstance.reviewCampaignPerformance({
          from: this.addr1,
        }),
        'non approver'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                            markCampaignComplete                            */
    /* -------------------------------------------------------------------------- */
    it('should mark the campaign as complete', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.reviewMode({ from: this.campaignOwner });
      await this.campaignInstance.reviewCampaignPerformance({
        from: this.addr1,
      });
      const receipt = await this.campaignInstance.markCampaignComplete({
        from: this.campaignOwner,
      });

      expect(
        (await this.campaignInstance.campaignState()).toString()
      ).to.be.equal('4');
      expectEvent(receipt, 'CampaignStateChange', {
        campaignId: new BN(this.campaignID),
        state: new BN('4'),
        sender: this.campaignOwner,
      });
    });
    it("campaign completion should fail if the review count doesn't exceed threshold mark", async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.root,
        value: 10000,
      });
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 10000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.root,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.reviewMode({ from: this.campaignOwner });
      await this.campaignInstance.reviewCampaignPerformance({
        from: this.addr1,
      });
      await expectRevert(
        this.campaignInstance.markCampaignComplete({
          from: this.campaignOwner,
        }),
        'review deficit'
      );
    });
    it('campaign completion should fail if the campaign state is not in review', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.voteOnRequest(0, 1, {
        from: this.addr1,
      });
      await this.campaignInstance.finalizeRequest(0, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.pauseCampaign({ from: this.root });
      // await this.campaignInstance.reviewCampaignPerformance({
      //   from: this.addr1,
      // });
      await expectRevert(
        this.campaignInstance.markCampaignComplete({
          from: this.campaignOwner,
        }),
        'not in review'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                               reportCampaign                               */
    /* -------------------------------------------------------------------------- */
    it('should report the campaign', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      const receipt = await this.campaignInstance.reportCampaign({
        from: this.addr1,
      });

      expect(await this.campaignInstance.reported(this.addr1)).to.be.equal(
        true
      );
      expect(await this.campaignInstance.reportCount()).to.be.bignumber.equal(
        new BN('1')
      );
      expect(await this.campaignInstance.paused()).to.be.equal(true);
      expect(
        (await this.campaignInstance.campaignState()).toString()
      ).to.be.equal('5');
      expectEvent(receipt, 'CampaignReported', {
        campaignId: new BN(this.campaignID),
        sender: this.addr1,
      });
    });
    it('campaign reporting should fail if the user is not an approver', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr2,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await expectRevert(
        this.campaignInstance.reportCampaign({
          from: this.addr1,
        }),
        'non approver'
      );
    });
    it('reporting a campaign should fail if state is not in collection or live state', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await this.campaignInstance.createRequest(this.addr3, 500, 86400, {
        from: this.campaignOwner,
      });
      await this.campaignInstance.setCampaignState(3, { from: this.root });
      await expectRevert(
        this.campaignInstance.reportCampaign({
          from: this.addr1,
        }),
        'not in collection or live state'
      );
    });
    it('reporting a campaign should fail if there are no requests made yet', async function () {
      let config: CampaignSetupConfig = {
        duration: 86400,
        from: this.campaignOwner,
      };
      await this.approvedCampaignSetup(config);
      await this.campaignInstance.contribute(this.testToken.address, 0, false, {
        from: this.addr1,
        value: 20000,
      });
      await expectRevert(
        this.campaignInstance.reportCampaign({
          from: this.addr1,
        }),
        'no requests'
      );
    });

    /* -------------------------------------------------------------------------- */
    /*                              setCampaignState                              */
    /* -------------------------------------------------------------------------- */
    it('should set the campaign state', async function () {
      await this.campaignInstance.setCampaignState(3, { from: this.root });

      expect(
        (await this.campaignInstance.campaignState()).toString()
      ).to.be.equal('3');
    });

    /* -------------------------------------------------------------------------- */
    /*                               unpauseCampaign                              */
    /* -------------------------------------------------------------------------- */
    it('should unpause the campaign', async function () {
      await this.campaignInstance.unpauseCampaign({ from: this.root });
      expect(await this.campaignInstance.paused()).to.be.equal(false);
    });

    /* -------------------------------------------------------------------------- */
    /*                                pauseCampaign                               */
    /* -------------------------------------------------------------------------- */
    it('should pause the campaign', async function () {
      await this.campaignInstance.unpauseCampaign({ from: this.root });
      await this.campaignInstance.pauseCampaign({ from: this.root });
      expect(await this.campaignInstance.paused()).to.be.equal(true);
    });
  }
);
