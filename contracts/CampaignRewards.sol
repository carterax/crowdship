// contracts/CampaignRewards.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./CampaignFactory.sol";
import "./Campaign.sol";

import "./interfaces/ICampaignFactory.sol";
import "./interfaces/ICampaign.sol";
import "./utils/AccessControl.sol";
import "./libraries/contracts/CampaignFactoryLib.sol";
import "./libraries/contracts/CampaignLib.sol";

contract CampaignRewards is Initializable, AccessControl {
    using SafeMathUpgradeable for uint256;

    /// @dev `Initializer Event`
    event CampaignRewardOwnerSet(
        address owner,
        address sender
    );

    /// @dev `Reward Events`
    event RewardCreated(
        uint256 indexed rewardId,
        uint256 value,
        uint256 deliveryDate,
        uint256 stock,
        bool active,
        address sender
    );
    event RewardModified(
        uint256 indexed rewardId,
        uint256 value,
        uint256 deliveryDate,
        uint256 stock,
        bool active,
        address sender
    );
    event RewardStockIncreased(
        uint256 indexed rewardId,
        uint256 count,
        address sender
    );
    event RewardDestroyed(
        uint256 indexed rewardId,
        address sender
    );

    /// @dev `Rward Recipient Events`
    event RewardRecipientAdded(
        uint256 indexed rewardId,
        uint256 amount,
        address sender
    );
    event RewarderApproval(
        uint256 indexed rewardRecipientId,
        bool status,
        address sender
    );
    event RewardRecipientApproval(
        uint256 indexed rewardRecipientId,
        address sender
    );

    ICampaignFactory public campaignFactoryContract;
    ICampaign public campaignContract;

    address public root;
    address public campaignRewardAddress;
    Campaign public campaign;
    uint256 public campaignID;

    /// @dev `Reward`
    struct Reward {
        uint256 value;
        uint256 deliveryDate;
        uint256 stock;
        bool exists;
        bool active;
    }
    Reward[] public rewards;
    mapping(uint256 => uint256) public rewardToRewardRecipientCount; // number of users eligible per reward

    /// @dev `RewardRecipient`
    struct RewardRecipient {
        uint256 rewardId;
        address user;
        bool deliveryConfirmedByCampaign;
        bool deliveryConfirmedByUser;
    }
    RewardRecipient[] public rewardRecipients;
    mapping(address => uint256) public userRewardCount; // number of rewards owned by a user

    /// @dev Ensures a user is verified
    modifier userIsVerified(address _user) {
        bool verified;
        (, verified) = CampaignFactoryLib.userInfo(
            campaignFactoryContract,
            _user
        );
        require(verified, "user not verified");
        _;
    }

    /// @dev Ensures caller is a registered campaign contract from factory
    modifier onlyRegisteredCampaigns() {
        address campaignAddress;

        (campaignAddress, , , , ) = CampaignFactoryLib.campaignInfo(
            campaignFactoryContract,
            campaignID
        );

        require(campaignAddress == msg.sender, "forbidden");
        _;
    }

    /**
     * @dev        Constructor
     * @param      _campaignFactory     Address of factory
     * @param      _campaignOwner                Address of campaign owner
     * @param      _campaignId          ID of campaign reward contract belongs to
     */
    function __CampaignRewards_init(
        CampaignFactory _campaignFactory,
        Campaign _campaign,
        address _campaignOwner,
        uint256 _campaignId
    ) public initializer {
        require(address(_campaignOwner) != address(0), "zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, _campaignOwner);

        campaignFactoryContract = ICampaignFactory(
            address(_campaignFactory)
        );
        campaignContract = ICampaign(address(_campaign));

        campaignID = _campaignId;
        campaign = _campaign;
        root = _campaignOwner;
        campaignRewardAddress = address(this);

        emit CampaignRewardOwnerSet(root, msg.sender);
    }

    /**
     * @dev        Creates rewards contributors can attain
     * @param      _value        Reward cost
     * @param      _deliveryDate Time in which reward will be deliverd to contriutors
     * @param      _stock        Quantity available for dispatch
     * @param      _active       Indicates if contributors can attain the reward
     */
    function createReward(
        uint256 _value,
        uint256 _deliveryDate,
        uint256 _stock,
        bool _active
    ) external onlyAdmin userIsVerified(msg.sender) {
        require(
            _value >
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minimumContributionAllowed"
                ),
            "amount too low"
        );
        require(
            _value <
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumContributionAllowed"
                ),
            "amount too high"
        );
        rewards.push(Reward(_value, _deliveryDate, _stock, true, _active));

        emit RewardCreated(
            rewards.length.sub(1),
            _value,
            _deliveryDate,
            _stock,
            _active,
            msg.sender
        );
    }

    /**
     * @dev        Assigns a reward to a user after payment from parent contract Campaign
     * @param      _rewardId     ID of the reward being assigned
     * @param      _amount       Amount being paid by the user
     * @param      _user         Address of user reward is being assigned to
     */
    function assignReward(
        uint256 _rewardId,
        uint256 _amount,
        address _user
    ) external onlyRegisteredCampaigns userIsVerified(_user) {
        require(_amount >= rewards[_rewardId].value, "amount too low");
        require(rewards[_rewardId].stock >= 1, "out of stock");
        require(rewards[_rewardId].exists, "not found");
        require(rewards[_rewardId].active, "not active");

        rewardRecipients.push(RewardRecipient(_rewardId, _user, false, false));
        userRewardCount[_user] = userRewardCount[_user].add(1);
        rewardToRewardRecipientCount[_rewardId] = rewardToRewardRecipientCount[
            _rewardId
        ].add(1);

        emit RewardRecipientAdded(_rewardId, _amount, _user);
    }

    /**
     * @dev        Modifies a reward by id
     * @param      _rewardId        Reward unique id
     * @param      _value           Reward cost
     * @param      _deliveryDate    Time in which reward will be deliverd to contriutors
     * @param      _stock           Quantity available for dispatch
     * @param      _active          Indicates if contributors can attain the reward
     */
    function modifyReward(
        uint256 _rewardId,
        uint256 _value,
        uint256 _deliveryDate,
        uint256 _stock,
        bool _active
    ) external onlyAdmin userIsVerified(msg.sender) {
        /**
         * To modify a reward:
         * check reward has no backers
         * check reward exists
         */
        require(rewards[_rewardId].exists, "not found");
        require(rewardToRewardRecipientCount[_rewardId] < 1, "has backers");
        require(
            _value >
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "minimumContributionAllowed"
                ),
            "amount too low"
        );
        require(
            _value <
                CampaignFactoryLib.getCampaignFactoryConfig(
                    campaignFactoryContract,
                    "maximumContributionAllowed"
                ),
            "amount too high"
        );

        rewards[_rewardId].value = _value;
        rewards[_rewardId].deliveryDate = _deliveryDate;
        rewards[_rewardId].stock = _stock;
        rewards[_rewardId].active = _active;

        emit RewardModified(
            _rewardId,
            _value,
            _deliveryDate,
            _stock,
            _active,
            msg.sender
        );
    }

    /**
     * @dev        Increases a reward stock count
     * @param      _rewardId        Reward unique id
     * @param      _count           Stock count to increase by
     */
    function increaseRewardStock(uint256 _rewardId, uint256 _count)
        external
        onlyAdmin
        userIsVerified(msg.sender)
    {
        require(rewards[_rewardId].exists, "not found");
        rewards[_rewardId].stock = rewards[_rewardId].stock.add(_count);

        emit RewardStockIncreased(_rewardId, _count, msg.sender);
    }

    /**
     * @dev        Deletes a reward by id
     * @param      _rewardId    Reward unique id
     */
    function destroyReward(uint256 _rewardId)
        external
        onlyAdmin
        userIsVerified(msg.sender)
    {
        // check reward has no backers
        require(rewardToRewardRecipientCount[_rewardId] < 1, "has backers");
        require(rewards[_rewardId].exists, "not found");

        delete rewards[_rewardId];

        emit RewardDestroyed(_rewardId, msg.sender);
    }

    /**
     * @dev        Called by the campaign owner to indicate they delivered the reward to the rewardRecipient
     * @param      _rewardRecipientId   ID to struct containing reward and user to be rewarded
     * @param      _status              Indicates if the delivery was successful or not
     */
    function campaignSentReward(uint256 _rewardRecipientId, bool _status)
        external
        userIsVerified(msg.sender)
        onlyAdmin
    {
        require(
            rewardToRewardRecipientCount[
                rewardRecipients[_rewardRecipientId].rewardId
            ] >= 1
        );

        rewardRecipients[_rewardRecipientId]
            .deliveryConfirmedByCampaign = _status;
        emit RewarderApproval(
            _rewardRecipientId,
            _status,
            msg.sender
        );
    }

    /**
     * @dev        Called by a user eligible for rewards to indicate they received their reward
     * @param      _rewardRecipientId  ID to struct containing reward and user to be rewarded
     */
    function userReceivedCampaignReward(uint256 _rewardRecipientId)
        external
        userIsVerified(msg.sender)
    {
        require(
            CampaignLib.isAnApprover(campaignContract, msg.sender),
            "not an approver"
        );
        require(
            rewardRecipients[_rewardRecipientId].deliveryConfirmedByCampaign,
            "reward not delivered yet"
        );
        require(
            !rewardRecipients[_rewardRecipientId].deliveryConfirmedByUser,
            "reward already marked as sent"
        );
        require(
            rewardRecipients[_rewardRecipientId].user == msg.sender,
            "not owner of reward"
        );

        require(userRewardCount[msg.sender] >= 1, "you have no reward");

        rewardRecipients[_rewardRecipientId].deliveryConfirmedByUser = true;
        emit RewardRecipientApproval(
            _rewardRecipientId,
            msg.sender
        );
    }

    /**
     * @dev        Renounces rewards owned by the specified user
     * @param      _user        Address of user who rewards are being renounced
     */
    function renounceRewards(address _user) external onlyRegisteredCampaigns {
        if (userRewardCount[_user] >= 1) {
            userRewardCount[_user] = 0;

            // deduct rewardRecipients count
            for (uint256 index = 0; index < rewardRecipients.length; index++) {
                rewardToRewardRecipientCount[
                    rewardRecipients[index].rewardId
                ] = rewardToRewardRecipientCount[
                    rewardRecipients[index].rewardId
                ].sub(1);
            }
        }
    }

    /**
     * @dev        Transfers rewards from the old owner to a new owner
     * @param      _oldAddress      Address of previous owner of rewards
     * @param      _newAddress      Address of new owner rewards are being transferred to
     */
    function transferRewards(address _oldAddress, address _newAddress)
        external
        onlyRegisteredCampaigns
    {
        if (userRewardCount[_oldAddress] >= 1) {
            userRewardCount[_newAddress] = userRewardCount[_oldAddress];
            userRewardCount[_oldAddress] = 0;

            for (uint256 index = 0; index < rewardRecipients.length; index++) {
                if (rewardRecipients[index].user == _oldAddress) {
                    rewardRecipients[index].user = _newAddress;
                }
            }
        }
    }
}
