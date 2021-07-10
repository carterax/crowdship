const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

module.exports = function() {
  /* -------------------------------------------------------------------------- */
  /*                               createCategory                               */
  /* -------------------------------------------------------------------------- */
  it('should create categories', async function() {
    const receipt = await this.factory.createCategory('Technology', true);

    expect((await this.factory.campaignCategories(0)).title).to.equal(
      'Technology'
    );
    expect((await this.factory.campaignCategories(0)).active).to.equal(true);
    expect((await this.factory.campaignCategories(0)).exists).to.equal(true);
    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('1')
    );
    expect(await this.factory.categoryIsTaken('Technology')).to.equal(true);
    expectEvent(receipt, 'CategoryAdded', {
      categoryId: new BN('0'),
      title: 'Technology',
      active: true,
    });
  });
  it('non managers cannot create category', async function() {
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true, { from: this.addr1 })
    );
  });
  it('address with role can create category', async function() {
    const MANAGE_USERS = await this.factory.MANAGE_USERS();
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();

    await this.factory.addRole(this.addr1, MANAGE_USERS);
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true, { from: this.addr1 })
    );

    await this.factory.addRole(this.addr1, MANAGE_CATEGORIES);
    await this.factory.createCategory('Sports', false, { from: this.addr1 });

    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('1')
    );
    expect(await this.factory.categoryIsTaken('Technology')).to.equal(false);
    expect(await this.factory.categoryIsTaken('Sports')).to.equal(true);
  });
  it('category creation should fail if category name is not unique', async function() {
    await this.factory.createCategory('Technology', true);
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true)
    );
  });
  it('category creation should fail if contract is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true)
    );
  });
  it('category creation should work if contract is unpaused', async function() {
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.createCategory('Charity', true);
    expect(await this.factory.categoryIsTaken('Charity')).to.equal(true);
  });

  /* -------------------------------------------------------------------------- */
  /*                               destroyCategory                              */
  /* -------------------------------------------------------------------------- */
  it('cannot delete a category that does not exist', async function() {
    expect(await this.factory.categoryIsTaken('Technology')).to.equal(false);
    await expectRevert.unspecified(this.factory.destroyCategory(0));
  });
  it('manager with role can delete category', async function() {
    await this.factory.createCategory('Gaming', false);
    const receipt = await this.factory.destroyCategory(0);
    const category = await this.factory.campaignCategories(0);

    expect(category.exists).to.be.equal(false);
    expect(await this.factory.categoryIsTaken(category.title)).to.be.equal(
      false
    );
    expectEvent(receipt, 'CategoryDestroyed', {
      categoryId: new BN('0'),
    });
  });
  it('cannot delete categories without role', async function() {
    await this.factory.createCategory('Gaming', false);
    await expectRevert.unspecified(
      this.factory.destroyCategory(0, { from: this.addr1 })
    );

    const category = await this.factory.campaignCategories(0);

    expect(category.exists).to.equal(true);
    expect(await this.factory.categoryIsTaken(category.title)).to.be.equal(
      true
    );
  });
  it('category destruction should fail if contract is paused', async function() {
    await this.factory.createCategory('Charity', true);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.destroyCategory(0));
  });
  it('category destruction should work if contract is unpaused', async function() {
    await this.factory.createCategory('Charity', true);
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
    await this.factory.createCategory('Cooking', true);
    await this.factory.createCategory('Health', false);
    await this.factory.createCategory('Technology', false);

    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('3')
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                               modifyCategory                               */
  /* -------------------------------------------------------------------------- */
  it('manager with role can modify category', async function() {
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();

    await this.factory.createCategory('Sports', false);
    await this.factory.addRole(this.addr1, MANAGE_CATEGORIES);

    const receipt = await this.factory.modifyCategory(0, 'Health', false, {
      from: this.addr1,
    });
    expect(await this.factory.categoryIsTaken('Health')).to.be.equal(true);
    expect(await this.factory.categoryIsTaken('Sports')).to.be.equal(false);
    expect((await this.factory.campaignCategories(0)).title).to.equal('Health');
    expect((await this.factory.campaignCategories(0)).active).to.be.equal(
      false
    );
    expect((await this.factory.campaignCategories(0)).exists).to.be.equal(true);
    expectEvent(receipt, 'CategoryModified', {
      categoryId: new BN('0'),
      title: 'Health',
      active: false,
    });
  });
  it('user without role cannot modify category', async function() {
    await this.factory.createCategory('Health', true);

    await expectRevert.unspecified(
      this.factory.modifyCategory(0, 'Sports', false, { from: this.addr3 })
    );
    expect((await this.factory.campaignCategories(0)).title).to.equal('Health');
    expect((await this.factory.campaignCategories(0)).active).to.equal(true);
  });
  it('category modification should fail if contract is paused', async function() {
    await this.factory.createCategory('Sports', true);
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.modifyCategory(0, 'Health', false)
    );
  });
  it('category modification should work if contract is unpaused', async function() {
    await this.factory.createCategory('Sports', true);
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.modifyCategory(0, 'Health', true);
    expect(await this.factory.categoryIsTaken('Health')).to.be.equal(true);
    expect((await this.factory.campaignCategories(0)).exists).to.be.equal(true);
  });
};
