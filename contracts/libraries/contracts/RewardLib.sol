// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../interfaces/IReward.sol";

library RewardLib {
    /**
     * @dev        Assigns a reward to the user
     * @param      _campaignReward     Campaign reward interface
     */
    function _assignReward(
        IReward _campaignReward,
        uint256 _rewardId,
        uint256 _amount,
        address _user
    ) internal returns (uint256) {
        return _campaignReward.assignReward(_rewardId, _amount, _user);
    }

    /**
     * @dev        Renounces rewards owned by the specified user
     * @param      _user        Address of user who rewards are being renounced
     */
    function _renounceRewards(
        IReward _campaignReward,
        address _user
    ) internal {
        _campaignReward.renounceRewards(_user);
    }

    /**
     * @dev        Transfers rewards from the old owner to a new owner
     * @param      _campaignReward  Campaign reward interface
     * @param      _oldAddress      Address of previous owner of rewards
     * @param      _newAddress      Address of new owner rewards are being transferred to
     */
    function _transferRewards(
        IReward _campaignReward,
        address _oldAddress,
        address _newAddress
    ) internal {
        _campaignReward.transferRewards(_oldAddress, _newAddress);
    }
}
