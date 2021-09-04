export {};
// /* -------------------------------------------------------------------------- */
// /*                                createReward                                */
// /* -------------------------------------------------------------------------- */
// it('should create a reward', async function() {
//   await this.campaignInstance.unpauseCampaign({ from: this.root });
//   const receipt = await this.campaignInstance.createReward(
//     100,
//     86400,
//     10,
//     true,
//     {
//       from: this.campaignOwner,
//     }
//   );
//   expect(
//     (await this.campaignInstance.rewards(0)).value
//   ).to.be.bignumber.equal(new BN('100'));
//   expect(
//     (await this.campaignInstance.rewards(0)).deliveryDate
//   ).to.be.bignumber.equal(new BN('86400'));
//   expect(
//     (await this.campaignInstance.rewards(0)).stock
//   ).to.be.bignumber.equal(new BN('10'));
//   expect((await this.campaignInstance.rewards(0)).active).to.be.equal(true);

//   expectEvent(receipt, 'RewardCreated', {
//     rewardId: new BN('0'),
//     campaignId: new BN(this.campaignID),
//     value: new BN('100'),
//     deliveryDate: new BN('86400'),
//     stock: new BN('10'),
//     active: true,
//   });
// });
// it('reward creation should fail if the cost is less than minimum allowed contribution', async function() {
//   const globalMinimumContributionAllowed = 200;
//   const campaignMinimumContributionAllowed = 300;

//   await this.factory.setCampaignTransactionConfig(
//     'minimumContributionAllowed',
//     globalMinimumContributionAllowed,
//     { from: this.root }
//   );
//   await this.campaignInstance.unpauseCampaign({ from: this.root });
//   await expectRevert.unspecified(
//     this.campaignInstance.createReward(100, 86400, 10, true, {
//       from: this.campaignOwner,
//     })
//   );
// });
// it('reward creation should fail if the cost is greater than maximum allowed contribution', async function() {
//   const globalMaximumContributionAllowed = 1000;
//   const campaignMaximumContributionAllowed = 1000;
//   const rewardCost = 20000;

//   await this.factory.setCampaignTransactionConfig(
//     'maximumContributionAllowed',
//     globalMaximumContributionAllowed,
//     { from: this.root }
//   );
//   await this.campaignInstance.unpauseCampaign({ from: this.root });
//   await expectRevert.unspecified(
//     this.campaignInstance.createReward(rewardCost, 86400, 10, true, {
//       from: this.campaignOwner,
//     })
//   );
// });

// /* -------------------------------------------------------------------------- */
// /*                                modifyReward                                */
// /* -------------------------------------------------------------------------- */
// it('should modify a reward', async function() {
//   await this.campaignInstance.unpauseCampaign({ from: this.root });
//   await this.campaignInstance.createReward(500, 86400, 10, true, {
//     from: this.campaignOwner,
//   });
//   const receipt = await this.campaignInstance.modifyReward(
//     0,
//     200,
//     86400,
//     3,
//     false
//   );
//   expect(
//     (await this.campaignInstance.rewards(0)).value
//   ).to.be.bignumber.equal(new BN('200'));
//   expect(
//     (await this.campaignInstance.rewards(0)).deliveryDate
//   ).to.be.bignumber.equal(new BN('86400'));
//   expect(
//     (await this.campaignInstance.rewards(0)).stock
//   ).to.be.bignumber.equal(new BN('3'));
//   expect((await this.campaignInstance.rewards(0)).active).to.be.equal(false);

//   expectEvent(receipt, 'RewardModified', {
//     rewardId: new BN('0'),
//     campaignId: new BN(this.campaignID),
//     value: new BN('200'),
//     deliveryDate: new BN('86400'),
//     stock: new BN('3'),
//     active: false,
//   });
// });
// it('should increase reward stock count', async function() {
//   await this.campaignInstance.unpauseCampaign({ from: this.root });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   const receipt = await this.campaignInstance.increaseRewardStock(0, 1);
//   expect(
//     (await this.campaignInstance.rewards(0)).stock
//   ).to.be.bignumber.equal(new BN('4'));
//   expectEvent(receipt, 'RewardStockIncreased', {
//     rewardId: new BN('0'),
//     campaignId: new BN(this.campaignID),
//     count: new BN('1'),
//   });
// });
// it('reward modification should fail if it has backers', async function() {
//   await this.approvedCampaignSetup({
//     duration: 86400,
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
//     from: this.root,
//     value: 600,
//   });
//   await expectRevert.unspecified(
//     this.campaignInstance.modifyReward(0, 200, 86400, 3, false, {
//       from: this.campaignOwner,
//     })
//   );
// });
// it("reward modification should fail if the reward doesn't exist", async function() {
//   await this.campaignInstance.unpauseCampaign({ from: this.root });
//   await expectRevert.unspecified(
//     this.campaignInstance.modifyReward(0, 200, 86400, 3, false, {
//       from: this.campaignOwner,
//     })
//   );
// });

// /* -------------------------------------------------------------------------- */
// /*                                destroyReward                               */
// /* -------------------------------------------------------------------------- */
// it('should delete a reward', async function() {
//   await this.campaignInstance.unpauseCampaign({ from: this.root });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   const receipt = await this.campaignInstance.destroyReward(0, {
//     from: this.campaignOwner,
//   });

//   expect(
//     (await this.campaignInstance.rewards(0)).value
//   ).to.be.bignumber.equal(new BN('0'));
//   expect(
//     (await this.campaignInstance.rewards(0)).deliveryDate
//   ).to.be.bignumber.equal(new BN('0'));
//   expect(
//     (await this.campaignInstance.rewards(0)).stock
//   ).to.be.bignumber.equal(new BN('0'));
//   expect((await this.campaignInstance.rewards(0)).active).to.be.equal(false);

//   expectEvent(receipt, 'RewardDestroyed', {
//     rewardId: new BN('0'),
//     campaignId: new BN(this.campaignID),
//   });
// });
// it('reward deletion should fail if the reward has backers', async function() {
//   await this.approvedCampaignSetup({
//     duration: 184000,
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
//     from: this.root,
//     value: 600,
//   });
//   await expectRevert.unspecified(
//     this.campaignInstance.destroyReward(0, { from: this.campaignOwner })
//   );
// });
// it("reward deletion should fail if the reward doesn't exist", async function() {
//   await this.campaignInstance.unpauseCampaign({ from: this.root });
//   await expectRevert.unspecified(
//     this.campaignInstance.destroyReward(0, { from: this.campaignOwner })
//   );
// });

// /* -------------------------------------------------------------------------- */
// /*                             campaignSentReward                             */
// /* -------------------------------------------------------------------------- */
// it('should mark a reward as delivered', async function() {
//   await this.approvedCampaignSetup({
//     duration: 184000,
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
//     from: this.root,
//     value: 600,
//   });
//   const receipt = await this.campaignInstance.campaignSentReward(0, true, {
//     from: this.campaignOwner,
//   });

//   expect(
//     (await this.campaignInstance.rewardRecipients(0))
//       .deliveryConfirmedByCampaign
//   ).to.be.equal(true);
//   expectEvent(receipt, 'RewarderApproval', {
//     rewardRecipientId: new BN('0'),
//     campaignId: new BN(this.campaignID),
//     status: true,
//   });
// });
// it('reward delivery update should fail if not called by the campaign owner', async function() {
//   await this.approvedCampaignSetup({
//     duration: 184000,
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
//     from: this.root,
//     value: 600,
//   });
//   await expectRevert.unspecified(
//     this.campaignInstance.campaignSentReward(0, true, {
//       from: this.addr3,
//     })
//   );
// });

// /* -------------------------------------------------------------------------- */
// /*                         userReceivedCampaignReward                         */
// /* -------------------------------------------------------------------------- */
// it('should mark a reward as received', async function() {
//   await this.approvedCampaignSetup({
//     duration: 184000,
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
//     from: this.root,
//     value: 600,
//   });
//   await this.campaignInstance.campaignSentReward(0, true, {
//     from: this.campaignOwner,
//   });
//   const receipt = await this.campaignInstance.userReceivedCampaignReward(0, {
//     from: this.root,
//   });

//   expect(
//     (await this.campaignInstance.rewardRecipients(0)).deliveryConfirmedByUser
//   ).to.be.equal(true);
//   expectEvent(receipt, 'RewardRecipientApproval', {
//     rewardRecipientId: new BN('0'),
//     campaignId: new BN(this.campaignID),
//   });
// });
// it('reward received should fail if reward delivery is marked false', async function() {
//   await this.approvedCampaignSetup({
//     duration: 184000,
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
//     from: this.root,
//     value: 600,
//   });
//   await expectRevert.unspecified(
//     this.campaignInstance.userReceivedCampaignReward(0, {
//       from: this.root,
//     })
//   );
// });
// it("reward received should fail if user isn't the owner of the reward", async function() {
//   await this.approvedCampaignSetup({
//     duration: 184000,
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
//     from: this.root,
//     value: 600,
//   });
//   await this.campaignInstance.campaignSentReward(0, true, {
//     from: this.campaignOwner,
//   });
//   await expectRevert.unspecified(
//     this.campaignInstance.userReceivedCampaignReward(0, {
//       from: this.addr1,
//     })
//   );
// });
// it("reward received should fail if the user isn't an approver", async function() {
//   await this.approvedCampaignSetup({
//     duration: 184000,
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.createReward(500, 86400, 3, true, {
//     from: this.campaignOwner,
//   });
//   await this.campaignInstance.contribute(this.testToken.address, 0, true, {
//     from: this.root,
//     value: 600,
//   });
//   await this.campaignInstance.campaignSentReward(0, true, {
//     from: this.campaignOwner,
//   });
//   await expectRevert.unspecified(
//     this.campaignInstance.userReceivedCampaignReward(0, {
//       from: this.addr1,
//     })
//   );
// });
