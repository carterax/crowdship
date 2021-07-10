const { expect } = require('chai');
const { internet } = require('faker');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

module.exports = function() {
  /* -------------------------------------------------------------------------- */
  /*                                   signUp                                   */
  /* -------------------------------------------------------------------------- */
  it('user can signup', async function() {
    const email = internet.email();
    const username = internet.userName();
    const receipt = await this.factory.signUp(email, username, {
      from: this.addr3,
    });
    const usersCount = await this.factory.userCount();
    const userId = await this.factory.userID(this.addr3);
    const user = await this.factory.users(userId);
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

    expect(usersCount).to.be.bignumber.equal(new BN('4'));
    expect(user.email).to.equal(email);
    expect(user.username).to.equal(username);
    expect(user.joined).to.be.bignumber.equal(new BN(block.timestamp));
    expect(user.updatedAt).to.be.bignumber.equal(new BN('0'));
    expect(user.verified).to.equal(false);
    expect(user.exists).to.equal(true);

    expectEvent(receipt, 'UserAdded', {
      userId: new BN(userId),
      email: email,
      username: username,
    });
  });
  it('user cannot sign up with taken username and email', async function() {
    await expectRevert.unspecified(
      this.factory.signUp(this.adminMail, this.adminUserName)
    );
  });
  it('sign up should fail if factory is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.signUp(internet.email(), internet.userName())
    );
  });
  it('sign up should work if factory is unpaused', async function() {
    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();
    await this.factory.signUp(internet.email(), internet.userName());
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
  /*                                 modifyUser                                 */
  /* -------------------------------------------------------------------------- */
  it('user or manager can modify user details', async function() {
    const newUserName = internet.userName(),
      newEmail = internet.email();

    const receipt = await this.factory.modifyUser(0, newEmail, newUserName);
    const block = await web3.eth.getBlock(receipt.receipt.blockNumber);

    const editedUser = await this.factory.users(0);

    expect(editedUser.username).to.equal(newUserName);
    expect(editedUser.email).to.equal(newEmail);
    expect(editedUser.verified).to.equal(false);
    expect(new BN(editedUser.updatedAt)).to.be.bignumber.equal(
      new BN(block.timestamp)
    );
    expect(await this.factory.emailIsTaken(newEmail)).to.equal(true);
    expect(await this.factory.emailIsTaken(this.adminMail)).to.equal(false);
    expect(await this.factory.usernameIsTaken(newUserName)).to.equal(true);
    expect(await this.factory.usernameIsTaken(this.adminUserName)).to.equal(
      false
    );
    expectEvent(receipt, 'UserModified', {
      userId: new BN('0'),
      email: newEmail,
      username: newUserName,
    });
  });
  it('cannot modify user if they do not exist', async function() {
    await expectRevert.unspecified(
      this.factory.modifyUser(6, internet.email(), internet.userName())
    );
  });
  it("user cannot modify another user's profile", async function() {
    await expectRevert.unspecified(
      this.factory.modifyUser(0, internet.email(), internet.userName(), {
        from: this.addr1,
      })
    );
  });
  it('user modification should fail if factory is paused', async function() {
    await this.factory.pauseCampaign();
    await expectRevert.unspecified(
      this.factory.modifyUser(0, internet.userName(), internet.email())
    );
  });
  it('user modification should work if factory is unpaused', async function() {
    let user, newUserName, newEmail, modifiedUser;

    await this.factory.pauseCampaign();
    await this.factory.unpauseCampaign();

    user = await this.factory.users(1);
    newUserName = internet.userName();
    newEmail = internet.email();
    await this.factory.modifyUser(1, newUserName, newEmail);
    modifiedUser = await this.factory.users(1);
    expect(new BN(user.updatedAt)).to.be.bignumber.lessThan(
      new BN(modifiedUser.updatedAt)
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                                 destroyUser                                */
  /* -------------------------------------------------------------------------- */
  it('manager with role can delete user', async function() {
    const receipt = await this.factory.destroyUser(2),
      user = await this.factory.users(2);

    expect((await this.factory.users(2)).exists).to.equal(false);
    expect((await this.factory.users(2)).verified).to.equal(false);
    expect(await this.factory.usernameIsTaken(user.username)).to.equal(false);
    expect(await this.factory.emailIsTaken(user.email)).to.equal(false);

    expectEvent(receipt, 'UserRemoved', { userId: new BN('2') });
  });
  it('user without role cannot delete user', async function() {
    await expectRevert.unspecified(
      this.factory.destroyUser(0, { from: this.addr3 })
    );
    expect((await this.factory.users(0)).exists).to.equal(true);
    expect((await this.factory.users(0)).verified).to.equal(true);
    expect(await this.factory.usernameIsTaken(this.adminUserName)).to.equal(
      true
    );
    expect(await this.factory.emailIsTaken(this.adminMail)).to.equal(true);
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
