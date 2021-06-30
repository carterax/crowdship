const { expect } = require('chai');
const { internet } = require('faker');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

module.exports = function () {
  it('user can signup', async function () {
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
      id: userId,
    });
  });

  it('user cannot sign up with taken username and email', async function () {
    await expectRevert.unspecified(
      this.factory.signUp(this.adminMail, this.adminUserName)
    );
  });

  it('should return total amount of users', async function () {
    const users = await this.factory.userCount();
    expect(users).to.be.bignumber.equal(new BN('3'));
  });

  it('address with role can approve and unapprove user', async function () {
    const MANAGE_USERS = await this.factory.MANAGE_USERS();
    const userId = await this.factory.userID(this.addr2);

    await this.factory.addRole(this.addr1, MANAGE_USERS);

    await this.factory.toggleUserApproval(userId, true, { from: this.addr1 });
    expect((await this.factory.users(userId)).verified).to.equal(true);

    await this.factory.toggleUserApproval(userId, false, { from: this.addr1 });
    expect((await this.factory.users(userId)).verified).to.equal(false);
  });

  it('address without role cannot approve user', async function () {
    const userId = await this.factory.userID(this.addr2);

    await expectRevert.unspecified(
      this.factory.toggleUserApproval(userId, true, { from: this.addr1 })
    );
  });

  it('cannot modify user if they do not exist', async function () {
    await expectRevert.unspecified(
      this.factory.modifyUser(6, internet.email(), internet.userName())
    );
  });

  it('user or manager can modify user details', async function () {
    const newUserName = internet.userName(),
      newEmail = internet.email();

    await this.factory.modifyUser(0, newEmail, newUserName);

    const editedUser = await this.factory.users(0);

    expect(editedUser.username).to.equal(newUserName);
    expect(editedUser.email).to.equal(newEmail);
    expect(editedUser.verified).to.equal(false);
    expect(await this.factory.emailIsTaken(newEmail)).to.equal(true);
    expect(await this.factory.emailIsTaken(this.adminMail)).to.equal(false);
    expect(await this.factory.usernameIsTaken(newUserName)).to.equal(true);
    expect(await this.factory.usernameIsTaken(this.adminUserName)).to.equal(
      false
    );
  });

  it("user cannot modify another user's profile", async function () {
    await expectRevert.unspecified(
      this.factory.modifyUser(0, internet.email(), internet.userName(), {
        from: this.addr1,
      })
    );
  });

  it('manager with role can delete user', async function () {
    const user = await this.factory.users(2),
      receipt = await this.factory.destroyUser(2);

    expect((await this.factory.users(2)).exists).to.equal(false);
    expect((await this.factory.users(2)).verified).to.equal(false);
    expect(await this.factory.usernameIsTaken(user.username)).to.equal(false);
    expect(await this.factory.emailIsTaken(user.email)).to.equal(false);

    expectEvent(receipt, 'UserRemoved', { id: new BN('2') });
  });

  it('user without role cannot delete user', async function () {
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

  it('should get users count', async function () {
    expect(await this.factory.userCount()).to.be.bignumber.equal(new BN('3'));
  });
};
