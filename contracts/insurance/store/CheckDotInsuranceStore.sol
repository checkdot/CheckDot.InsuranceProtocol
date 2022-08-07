// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/IERC20.sol";
import "../../interfaces/IDAOProxy.sol";
import "../../utils/StoreAddresses.sol";
import "../../utils/StoreUpdates.sol";

import "../../../../../CheckDot.DAOProxyContract/contracts/interfaces/IOwnedProxy.sol";

contract CheckDotInsuranceStore {

    using StoreAddresses for StoreAddresses.StoreAddressesSlot;
    using StoreUpdates for StoreUpdates.Updates;
    using StoreUpdates for StoreUpdates.Update;

    /**
     * @dev Store slot with the upgrades of the contract.
     * This is the keccak-256 hash of "io.checkdot.index.updates" subtracted by 1
     */
    bytes32 private constant _INDEX_UPDATES_SLOT = 0xa6e9f6f4f5f44cd389c65f0f1dce0abd10b43565e36a1246ece73be4a7146964;

    /**
     * @dev Store slot with the keys of the contract.
     * This is the keccak-256 hash of "io.checkdot.index.keys" subtracted by 1
     */
    bytes32 private constant _INDEX_KEYS_SLOT = 0x50be8a13ecec2d77a06a6bd58c41283bea83050138a149f5656e98c79439ee4a;

    function initialize() external payable {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "FORBIDDEN");
        // unused
    }

    /**
     * @dev Creation and update function of one key address value,
     * the entry of a start date and an end date of the voting period by
     * the governance is necessary. The start date of the period must be
     * greater or equals than the `block.timestamp`.
     * The start date and end date of the voting period must be at least
     * 86400 seconds apart.
     */
    function updateAddress(string calldata _key, address _newAddress, uint256 _utcStartVote, uint256 _utcEndVote) external payable {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "FORBIDDEN");
        require(_utcStartVote >= block.timestamp, "EXPIRED");
        require(_utcEndVote >= (_utcStartVote + 86400), "MINIMUM_SPACING");
        StoreUpdates.Updates storage _updates = StoreUpdates.getUpdatesSlot(_INDEX_UPDATES_SLOT).value;

        require(_updates.isEmpty() || _updates.current().isFinished, "UPGRADE_ALREADY_INPROGRESS");
        _updates.add(_key, _newAddress, _utcStartVote, _utcEndVote);
    }

    /**
     * @dev Function to check the result of the vote of the key index
     * update.
     * Only called by the owner and if the vote is favorable the
     * key address is changed.
     */
    function voteUpdateCounting() external payable {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "FORBIDDEN");
        StoreUpdates.Updates storage _updates = StoreUpdates.getUpdatesSlot(_INDEX_UPDATES_SLOT).value;

        require(!_updates.isEmpty(), "EMPTY");
        require(_updates.current().voteFinished(), "VOTE_ALREADY_INPROGRESS");
        require(!_updates.current().isFinished, "UPGRADE_ALREADY_FINISHED");

        _updates.current().setFinished(true);
        if (_updates.current().totalApproved > _updates.current().totalUnapproved) {
            _updateAddress(_updates.current().key, _updates.current().value);
        }
    }

    /**
     * @dev Function callable by the holders of at least one unit of the
     * governance token.
     * A voter can only vote once per update.
     */
    function voteUpdate(bool approve) external payable {
        StoreUpdates.Updates storage _updates = StoreUpdates.getUpdatesSlot(_INDEX_UPDATES_SLOT).value;

        require(!_updates.isEmpty(), "EMPTY");
        require(!_updates.current().isFinished, "VOTE_FINISHED");
        require(_updates.current().voteInProgress(), "VOTE_NOT_STARTED");
        require(!_updates.current().hasVoted(_updates, msg.sender), "ALREADY_VOTED");
        IERC20 token = IERC20(IDAOProxy(address(this)).getGovernance());
        uint256 votes = token.balanceOf(msg.sender) - (1**token.decimals());
        require(votes >= 1, "INSUFFISANT_POWER");

        _updates.current().vote(_updates, msg.sender, votes, approve);
    }

    /**
     * @dev Returns the array of all updated keys.
     */
    function getAllUpdates() external view returns (StoreUpdates.Update[] memory) {
        return StoreUpdates.getUpdatesSlot(_INDEX_UPDATES_SLOT).value.all();
    }

    /**
     * @dev Returns the key last update.
     */
    function getLastUpdate() external view returns (StoreUpdates.Update memory) {
        return StoreUpdates.getUpdatesSlot(_INDEX_UPDATES_SLOT).value.getLastUpdate();
    }

    /**
     * @dev Returns the Insurance Protocol addresses.
     */
    function getAddress(string calldata _key) external view returns (address) {
        return StoreAddresses.getStoreAddressesSlot(_INDEX_KEYS_SLOT).value[_key];
    }

    /**
     * @dev Stores a new addresses of the Insurance Protocol.
     */
    function _setAddress(string storage _key, address _newKeyAddress) internal {
        StoreAddresses.getStoreAddressesSlot(_INDEX_KEYS_SLOT).value[_key] = _newKeyAddress;
    }

    /**
     * @dev Stores a new Insurance Protocol address by key index.
     */
    function _updateAddress(string storage _key, address _newKeyAddress) internal {
        _setAddress(_key, _newKeyAddress);
    }

}