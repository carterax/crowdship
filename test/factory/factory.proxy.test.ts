export {};
const { expect } = require('chai');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const { BN } = require('@openzeppelin/test-helpers');

// Load compiled artifacts
const Factory = artifacts.require('CampaignFactory');
const Campaign = artifacts.require('Campaign');
const CampaignRewards = artifacts.require('CampaignRewards');

contract('Factory (proxy)', function ([root, factoryWallet]) {
  beforeEach(async function () {
    this.campaignImplementation = await Campaign.new();
    this.campaignRewardsImplementation = await CampaignRewards.new();

    this.factory = await deployProxy(
      Factory,
      [
        factoryWallet,
        this.campaignImplementation.address,
        this.campaignRewardsImplementation.address,
      ],
      {
        initializer: '__CampaignFactory_init',
      }
    );
  });

  it('root and factory wallet should be initialized', async function () {
    expect(await this.factory.root()).to.equal(root);
    expect(await this.factory.factoryWallet()).to.equal(factoryWallet);
  });

  it('transaction configs should be initialized', async function () {
    expect(
      await this.factory.campaignTransactionConfig('defaultCommission')
    ).to.be.bignumber.equal(new BN('2'));
    expect(
      await this.factory.campaignTransactionConfig('deadlineStrikesAllowed')
    ).to.be.bignumber.equal(new BN('3'));
    expect(
      await this.factory.campaignTransactionConfig('minimumContributionAllowed')
    ).to.be.bignumber.equal(new BN('1'));
    expect(
      await this.factory.campaignTransactionConfig('maximumContributionAllowed')
    ).to.be.bignumber.equal(new BN('10000'));
    expect(
      await this.factory.campaignTransactionConfig(
        'minimumRequestAmountAllowed'
      )
    ).to.be.bignumber.equal(new BN('1000'));
    expect(
      await this.factory.campaignTransactionConfig(
        'maximumRequestAmountAllowed'
      )
    ).to.be.bignumber.equal(new BN('5000'));
    expect(
      await this.factory.campaignTransactionConfig('minimumCampaignTarget')
    ).to.be.bignumber.equal(new BN('5000'));
    expect(
      await this.factory.campaignTransactionConfig('maximumCampaignTarget')
    ).to.be.bignumber.equal(new BN('1000000'));
    expect(
      await this.factory.campaignTransactionConfig('maxDeadlineExtension')
    ).to.be.bignumber.equal(new BN('604800'));
    expect(
      await this.factory.campaignTransactionConfig('minDeadlineExtension')
    ).to.be.bignumber.equal(new BN('86400'));
    expect(
      await this.factory.campaignTransactionConfig('minRequestDuration')
    ).to.be.bignumber.equal(new BN('86400'));
    expect(
      await this.factory.campaignTransactionConfig('maxRequestDuration')
    ).to.be.bignumber.equal(new BN('604800'));
    expect(
      await this.factory.campaignTransactionConfig('reviewThresholdMark')
    ).to.be.bignumber.equal(new BN('80'));
    expect(
      await this.factory.campaignTransactionConfig(
        'requestFinalizationThreshold'
      )
    ).to.be.bignumber.equal(new BN('51'));
    expect(
      await this.factory.campaignTransactionConfig('reportThresholdMark')
    ).to.be.bignumber.equal(new BN('51'));
  });

  it('implementation address for Campaign and CampaignRewards should be initialized', async function () {
    expect(await this.factory.campaignImplementation()).to.equal(
      this.campaignImplementation.address
    );
    expect(await this.factory.campaignRewardsImplementation()).to.equal(
      this.campaignRewardsImplementation.address
    );
  });

  it('should initialize default roles', async function () {
    const DEFAULT_ADMIN_ROLE = await this.factory.DEFAULT_ADMIN_ROLE();
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();
    const MANAGE_CAMPAIGNS = await this.factory.MANAGE_CAMPAIGNS();
    const MANAGE_USERS = await this.factory.MANAGE_USERS();

    expect(await this.factory.hasRole(DEFAULT_ADMIN_ROLE, root)).to.equal(true);
    expect(await this.factory.hasRole(MANAGE_CATEGORIES, root)).to.equal(true);
    expect(await this.factory.hasRole(MANAGE_CAMPAIGNS, root)).to.equal(true);
    expect(await this.factory.hasRole(MANAGE_USERS, root)).to.equal(true);
  });

  it('should initialize root as a user', async function () {
    const usersCount = await this.factory.userCount();
    const userId = await this.factory.userID(root);
    const user = await this.factory.users(userId);

    expect(usersCount).to.be.bignumber.equal(new BN('1'));
    expect(user.verified).to.equal(false);
    expect(user.exists).to.equal(true);
  });
});
