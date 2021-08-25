export {};
const { expect } = require('chai');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

module.exports = function() {
  /* -------------------------------------------------------------------------- */
  /*                                   signUp                                   */
  /* -------------------------------------------------------------------------- */
  it('user can signup', async function() {
    const receipt = await this.factory.signUp({
      from: this.addr3,
    });
    const usersCount = await this.factory.userCount();
    const userId = await this.factory.userID(this.addr3);
    const user = await this.factory.users(userId);
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

    expect(usersCount).to.be.bignumber.equal(new BN('4'));
    expect(user.joined).to.be.bignumber.equal(new BN(block.timestamp));
    expect(user.updatedAt).to.be.bignumber.equal(new BN('0'));
    expect(user.verified).to.equal(false);
    expect(user.exists).to.equal(true);

    expectEvent(receipt, 'UserAdded', {
      userId: new BN(userId),
    });
  });
  it('sign up should fail if factory is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.signUp({ from: this.addr3 }));
  });
  it('sign up should work if factory is unpaused', async function() {
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.signUp({ from: this.addr3 });
    const userId = await this.factory.userID(this.addr3);
    const user = await this.factory.users(userId);
    expect(user.exists).to.equal(true);
  });

  /* -------------------------------------------------------------------------- */
  /*                                  userCount                                 */
  /* -------------------------------------------------------------------------- */
  it('should return total amount of users', async function() {
    const users = await this.factory.userCount();
    expect(new BN(users)).to.be.bignumber.equal(new BN('3'));
  });

  /* -------------------------------------------------------------------------- */
  /*                             toggleUserApproval                             */
  /* -------------------------------------------------------------------------- */
  it('address with role can approve and disapprove user', async function() {
    const MANAGE_USERS = await this.factory.MANAGE_USERS();
    const userId = await this.factory.userID(this.addr2);
    let receipt;

    await this.factory.addRole(this.addr1, MANAGE_USERS);

    receipt = await this.factory.toggleUserApproval(userId, true, {
      from: this.addr1,
    });
    expectEvent(receipt, 'UserApproval', {
      userId: new BN(userId),
      approval: true,
    });
    expect((await this.factory.users(userId)).verified).to.equal(true);

    receipt = await this.factory.toggleUserApproval(userId, false, {
      from: this.addr1,
    });
    expectEvent(receipt, 'UserApproval', {
      userId: new BN(userId),
      approval: false,
    });
    expect((await this.factory.users(userId)).verified).to.equal(false);
  });
  it('address without role cannot approve user', async function() {
    const userId = await this.factory.userID(this.addr2);

    await expectRevert.unspecified(
      this.factory.toggleUserApproval(userId, true, { from: this.addr1 })
    );
  });
  it('user approval should fail if factory is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.toggleUserApproval(1, true));
  });
  it('user approval should work if factory is unpaused', async function() {
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.toggleUserApproval(1, true);
    expect((await this.factory.users(1)).verified).to.equal(true);
  });

  /* -------------------------------------------------------------------------- */
  /*                                 destroyUser                                */
  /* -------------------------------------------------------------------------- */
  it('manager with role can delete user', async function() {
    const receipt = await this.factory.destroyUser(2),
      user = await this.factory.users(2);

    expect((await this.factory.users(2)).exists).to.equal(false);
    expect((await this.factory.users(2)).verified).to.equal(false);

    expectEvent(receipt, 'UserRemoved', { userId: new BN('2') });
  });
  it('user without role cannot delete user', async function() {
    await expectRevert.unspecified(
      this.factory.destroyUser(0, { from: this.addr3 })
    );
    expect((await this.factory.users(0)).exists).to.equal(true);
    expect((await this.factory.users(0)).verified).to.equal(true);
  });
  it('user destruction should fail if factory is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(this.factory.destroyUser(0));
  });
  it('user destruction should work if factory is unpaused', async function() {
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.destroyUser(1);
    const user = await this.factory.users(1);
    expect(user.exists).to.be.equal(false);
  });
};
