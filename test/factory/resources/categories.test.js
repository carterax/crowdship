const { expect } = require('chai');
const { BN, expectRevert } = require('@openzeppelin/test-helpers');
const { lorem } = require('faker');

module.exports = function () {
  it('deployer can create category', async function () {
    await this.factory.createCategory('Technology', true);
    await this.factory.createCategory('Health', true);

    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('2')
    );
    expect(await this.factory.categoryIsTaken('Technology')).to.equal(true);
    expect(await this.factory.categoryIsTaken('Health')).to.equal(true);
  });

  it('non managers cannot create category', async function () {
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true, { from: this.addr1 })
    );
  });

  it('address with role can create category', async function () {
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

  it('category name must be unique', async function () {
    await this.factory.createCategory('Technology', true);
    await expectRevert.unspecified(
      this.factory.createCategory('Technology', true)
    );
  });

  it('cannot delete a category that does not exist', async function () {
    expect(await this.factory.categoryIsTaken('Technology')).to.equal(false);
    await expectRevert.unspecified(this.factory.destroyCategory(0));
  });

  it('manager with role can delete category', async function () {
    await this.factory.createCategory('Gaming', false);
    await this.factory.destroyCategory(0);

    const category = await this.factory.campaignCategories(0);

    expect(category.exists).to.equal(false);
    expect(await this.factory.categoryIsTaken(category.title)).to.equal(false);
  });

  it('cannot delete categories without role', async function () {
    await this.factory.createCategory('Gaming', false);
    await expectRevert.unspecified(
      this.factory.destroyCategory(0, { from: this.addr1 })
    );

    const category = await this.factory.campaignCategories(0);

    expect(category.exists).to.equal(true);
    expect(await this.factory.categoryIsTaken(category.title)).to.equal(true);
  });

  it('can return total amount of categories', async function () {
    await this.factory.createCategory('Cooking', true);
    await this.factory.createCategory('Health', false);
    await this.factory.createCategory('Technology', false);

    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('3')
    );
  });

  it('can return categories count', async function () {
    await this.factory.createCategory('Cooking', true);
    await this.factory.createCategory('Health', false);
    await this.factory.createCategory('Technology', false);

    expect(await this.factory.categoryCount()).to.be.bignumber.equal(
      new BN('3')
    );
  });

  it('manager with role can modify category', async function () {
    const MANAGE_CATEGORIES = await this.factory.MANAGE_CATEGORIES();

    await this.factory.createCategory('Sports', false);
    await this.factory.addRole(this.addr1, MANAGE_CATEGORIES);

    await this.factory.modifyCategory(0, 'Sports', true, { from: this.addr1 });
    expect((await this.factory.campaignCategories(0)).title).to.equal('Sports');
    expect((await this.factory.campaignCategories(0)).active).to.equal(true);

    await this.factory.modifyCategory(0, 'Health', false, { from: this.addr1 });
    expect(await this.factory.categoryIsTaken('Health')).to.equal(true);
    expect(await this.factory.categoryIsTaken('Sports')).to.equal(false);
    expect((await this.factory.campaignCategories(0)).title).to.equal('Health');
    expect((await this.factory.campaignCategories(0)).active).to.equal(false);
  });

  it('user without role cannot modify category', async function () {
    await this.factory.createCategory('Health', true);

    await expectRevert.unspecified(
      this.factory.modifyCategory(0, 'Sports', false, { from: this.addr3 })
    );
    expect((await this.factory.campaignCategories(0)).title).to.equal('Health');
    expect((await this.factory.campaignCategories(0)).active).to.equal(true);
  });

  it("cannot create campaign if category isn't active and does not exist", async function () {
    await expectRevert.unspecified(
      this.factory.createCampaign(300, 0, lorem.sentence(), lorem.paragraph())
    ); // cat does not exist

    await this.factory.createCategory('Sports', false);
    await expectRevert.unspecified(
      this.factory.createCampaign(1200, 0, lorem.sentence(), lorem.paragraph())
    ); // cat not active
  });
};
