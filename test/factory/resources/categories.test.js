const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

module.exports = function() {
  /* -------------------------------------------------------------------------- */
  /*                               createCategory                               */
  /* -------------------------------------------------------------------------- */
  it('should create categories', async function() {
    const receipt = await this.factory.createCategory(true);

    expect((await this.factory.campaignCategories(0)).active).to.equal(true);
    expect((await this.factory.campaignCategories(0)).exists).to.equal(true);
    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('1')
    );
    expectEvent(receipt, 'CategoryAdded', {
      categoryId: new BN('0'),
      active: true,
    });
  });
  it('non managers cannot create category', async function() {
    await expectRevert.unspecified(
      this.factory.createCategory(true, { from: this.addr1 })
    );
  });
  it('address with role can create category', async function() {
    const MANAGE_USERS = await this.factory.MANAGE_USERS();
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();

    await this.factory.addRole(this.addr1, MANAGE_USERS);
    await expectRevert.unspecified(
      this.factory.createCategory(true, { from: this.addr1 })
    );

    await this.factory.addRole(this.addr1, MANAGE_CATEGORIES);
    await this.factory.createCategory(false, { from: this.addr1 });

    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('1')
    );
  });
  it('category creation should fail if contract is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.createCategory(true));
  });
  it('category creation should work if contract is unpaused', async function() {
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.createCategory(true);
    expect((await this.factory.campaignCategories(0)).exists).to.equal(true);
  });

  /* -------------------------------------------------------------------------- */
  /*                               destroyCategory                              */
  /* -------------------------------------------------------------------------- */
  it('cannot delete a category that does not exist', async function() {
    await expectRevert.unspecified(this.factory.destroyCategory(0));
  });
  it('manager with role can delete category', async function() {
    await this.factory.createCategory(false);
    const receipt = await this.factory.destroyCategory(0);
    const category = await this.factory.campaignCategories(0);

    expect(category.exists).to.be.equal(false);
    expectEvent(receipt, 'CategoryDestroyed', {
      categoryId: new BN('0'),
    });
  });
  it('cannot delete categories without role', async function() {
    await this.factory.createCategory(false);
    await expectRevert.unspecified(
      this.factory.destroyCategory(0, { from: this.addr1 })
    );

    const category = await this.factory.campaignCategories(0);

    expect(category.exists).to.equal(true);
  });
  it('category destruction should fail if contract is paused', async function() {
    await this.factory.createCategory(true);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.destroyCategory(0));
  });
  it('category destruction should work if contract is unpaused', async function() {
    await this.factory.createCategory(true);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.destroyCategory(0);
    const category = await this.factory.campaignCategories(0);
    expect(category.exists).to.be.equal(false);
  });

  /* -------------------------------------------------------------------------- */
  /*                                categoryCount                               */
  /* -------------------------------------------------------------------------- */
  it('can return categories count', async function() {
    await this.factory.createCategory(true);
    await this.factory.createCategory(false);
    await this.factory.createCategory(false);

    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('3')
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                               modifyCategory                               */
  /* -------------------------------------------------------------------------- */
  it('manager with role can modify category', async function() {
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();

    await this.factory.createCategory(false);
    await this.factory.addRole(this.addr1, MANAGE_CATEGORIES);

    const receipt = await this.factory.modifyCategory(0, false, {
      from: this.addr1,
    });
    expect((await this.factory.campaignCategories(0)).active).to.be.equal(
      false
    );
    expect((await this.factory.campaignCategories(0)).exists).to.be.equal(true);
    expectEvent(receipt, 'CategoryModified', {
      categoryId: new BN('0'),
      active: false,
    });
  });
  it('user without role cannot modify category', async function() {
    await this.factory.createCategory(true);

    await expectRevert.unspecified(
      this.factory.modifyCategory(0, false, { from: this.addr3 })
    );
    expect((await this.factory.campaignCategories(0)).active).to.equal(true);
  });
  it('category modification should fail if contract is paused', async function() {
    await this.factory.createCategory(true);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.modifyCategory(0, false));
  });
  it('category modification should work if contract is unpaused', async function() {
    await this.factory.createCategory(true);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.modifyCategory(0, true);
    expect((await this.factory.campaignCategories(0)).exists).to.be.equal(true);
  });
};
