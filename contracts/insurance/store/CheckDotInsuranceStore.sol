// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/IERC20.sol";
import "../../interfaces/IDAOProxy.sol";
import "../../utils/StoreAddresses.sol";

import "../../../../../CheckDot.DAOProxyContract/contracts/interfaces/IOwnedProxy.sol";

contract CheckDotInsuranceStore {
    using StoreAddresses for StoreAddresses.StoreAddressesSlot;

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

    function initialize(bytes memory _data) external onlyOwner {
        // unused
    }

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "FORBIDDEN");
        _;
    }

    /**
     * @dev Update function of one key address value
     */
    function updateAddress(string calldata _key, address _newAddress) external onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "FORBIDDEN");
        require(bytes(_key).length > 0, "FORBIDEN");

        _updateAddress(_key, _newAddress);
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
    function _setAddress(string calldata _key, address _newKeyAddress) internal {
        StoreAddresses.getStoreAddressesSlot(_INDEX_KEYS_SLOT).value[_key] = _newKeyAddress;
    }

    /**
     * @dev Stores a new Insurance Protocol address by key index.
     */
    function _updateAddress(string calldata _key, address _newKeyAddress) internal {
        _setAddress(_key, _newKeyAddress);
    }

}