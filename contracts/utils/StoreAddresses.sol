// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title IndexAddresses
 * @author Jeremy Guyet (@jguyet)
 * @dev Library to manage the storage of mapped addresses.
 */
library StoreAddresses {
    struct StoreAddressesSlot {
        mapping(string => address) value;
    }

    /**
     * @dev Returns an `StoreAddressesSlot` with member `value` located at `slot`.
     */
    function getStoreAddressesSlot(bytes32 slot) internal pure returns (StoreAddressesSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}