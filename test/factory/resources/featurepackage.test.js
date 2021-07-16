const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

module.exports = function() {
  /* -------------------------------------------------------------------------- */
  /*                            createFeaturePackage                            */
  /* -------------------------------------------------------------------------- */
  it('should create a feature package', async function() {
    const receipt = await this.factory.createFeaturePackage(1000, 84600);
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);
    const {
      createdAt,
      updatedAt,
      cost,
      time,
      exists,
    } = await this.factory.featurePackages(0);

    expect(await this.factory.featurePackageCount()).to.be.bignumber.equal(
      new BN('1')
    );
    expect(createdAt).to.be.bignumber.equal(new BN(block.timestamp));
    expect(updatedAt).to.be.bignumber.equal(new BN('0'));
    expect(cost).to.be.bignumber.equal(new BN('1000'));
    expect(time).to.be.bignumber.equal(new BN('84600'));
    expect(exists).to.be.equal(true);
    expectEvent(receipt, 'FeaturePackageAdded', {
      packageId: new BN('0'),
      cost: new BN('1000'),
      time: new BN('84600'),
    });
  });
  it('feature package creation should fail if not admin', async function() {
    await expectRevert.unspecified(
      this.factory.createFeaturePackage(1000, 84600, {
        from: this.addr2,
      })
    );
  });
  it('feature package creation should fail if factory is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.createFeaturePackage(1000, 84600)
    );
  });
  it('feature package creation should work if factory is unpaused', async function() {
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.createFeaturePackage(1000, 84600);
    expect((await this.factory.featurePackages(0)).exists).to.be.equal(true);
  });

  /* -------------------------------------------------------------------------- */
  /*                            modifyFeaturedPackage                           */
  /* -------------------------------------------------------------------------- */
  it('should modify feature package', async function() {
    await this.factory.createFeaturePackage(1000, 84600);
    const receipt = await this.factory.modifyFeaturedPackage(0, 2000, 172800);
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);
    const { cost, time, updatedAt } = await this.factory.featurePackages(0);
    expect(cost).to.be.bignumber.equal(new BN('2000'));
    expect(time).to.be.bignumber.equal(new BN('172800'));
    expect(updatedAt).to.be.bignumber.equal(new BN(block.timestamp));
    expectEvent(receipt, 'FeaturePackageModified', {
      packageId: new BN('0'),
      cost: new BN('2000'),
      time: new BN('172800'),
    });
  });
  it('feature package modification should fail if package does not exist', async function() {
    await expectRevert.unspecified(
      this.factory.modifyFeaturedPackage(0, 1000, 86400)
    );
  });
  it('feature package modification should fail if not admin', async function() {
    await this.factory.createFeaturePackage(1000, 84600);
    await expectRevert.unspecified(
      this.factory.modifyFeaturedPackage(0, 2000, 96400, {
        from: this.addr2,
      })
    );
  });
  it('feature package modification should fail if factory is paused', async function() {
    await this.factory.createFeaturePackage(1000, 84600);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.modifyFeaturedPackage(0, 300, 10000)
    );
  });
  it('feature package modification should work if factory is unpaused', async function() {
    await this.factory.createFeaturePackage(1000, 84600);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    const newCost = 2000,
      newTime = 96400;
    const receipt = await this.factory.modifyFeaturedPackage(
      0,
      newCost,
      newTime
    );
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);
    const { cost, time, updatedAt } = await this.factory.featurePackages(0);
    expect(updatedAt).to.be.bignumber.equal(new BN(block.timestamp));
    expect(cost).to.be.bignumber.equal(new BN(newCost));
    expect(time).to.be.bignumber.equal(new BN(newTime));
    expectEvent(receipt, 'FeaturePackageModified', {
      packageId: new BN('0'),
      cost: new BN(newCost),
      time: new BN(newTime),
    });
  });

  /* -------------------------------------------------------------------------- */
  /*                           destroyFeaturedPackage                           */
  /* -------------------------------------------------------------------------- */
  it('should destroy feature package', async function() {
    await this.factory.createFeaturePackage(1000, 84600);
    const receipt = await this.factory.destroyFeaturedPackage(0);
    const destroyedPackage = await this.factory.featurePackages(0);
    expect(destroyedPackage.exists).to.be.equal(false);
    expectEvent(receipt, 'FeaturePackageDestroyed', {
      packageId: new BN('0'),
    });
  });
  it('feature package destruction should fail if feature package does not exist', async function() {
    await expectRevert.unspecified(this.factory.destroyFeaturedPackage(0));
  });
  it('feature package destruction should fail if not admin', async function() {
    await this.factory.createFeaturePackage(1000, 84600);
    await expectRevert.unspecified(
      this.factory.destroyFeaturedPackage(0, { from: this.addr2 })
    );
  });
  it('feature package destruction should fail if factory is paused', async function() {
    await this.factory.createFeaturePackage(1000, 84600);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.destroyFeaturedPackage(0));
    expect((await this.factory.featurePackages(0)).exists).to.be.equal(true);
  });
  it('feature package destruction should work if factory is unpaused', async function() {
    await this.factory.createFeaturePackage(1000, 84600);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    const receipt = await this.factory.destroyFeaturedPackage(0);
    const destroyedPackage = await this.factory.featurePackages(0);
    expect(destroyedPackage.exists).to.be.equal(false);
    expectEvent(receipt, 'FeaturePackageDestroyed', {
      packageId: new BN('0'),
    });
  });
};
