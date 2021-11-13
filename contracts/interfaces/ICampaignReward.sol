// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract ICampaignReward {
    address public campaignRewardAddress;

    function assignReward(
        uint256 _rewardId,
        uint256 _amount,
        address _user
    ) external virtual returns (uint256);

    function renounceRewards(address _user) external virtual;

    function transferRewards(address _oldAddress, address _newAddress)
        external
        virtual;
}
