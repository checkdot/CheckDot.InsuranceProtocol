// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title StoreUpdates
 * @author Jeremy Guyet (@jguyet)
 * @dev Provides a library allowing the management of updates.
 */
library StoreUpdates {

    struct Update {
        uint256 id;
        string  key;
        address value;
        uint256 utcStartVote;
        uint256 utcEndVote;
        uint256 totalApproved;
        uint256 totalUnapproved;
        bool isFinished;
    }

    struct Updates {
        mapping(uint256 => Update) updates;
        mapping(uint256 => mapping(address => address)) participators;
        uint256 counter;
    }

    struct UpdatesSlot {
        Updates value;
    }

    /////////
    // Updates View
    /////////

    function isEmpty(Updates storage updates) internal view returns (bool) {
        return updates.counter == 0;
    }

    function current(Updates storage updates) internal view returns (Update storage) {
        return updates.updates[updates.counter - 1];
    }

    function all(Updates storage updates) internal view returns (Update[] memory) {
        uint256 totalUpdates = updates.counter;
        Update[] memory results = new Update[](totalUpdates);
        uint256 index = 0;

        for (index; index < totalUpdates; index++) {
            Update storage update = updates.updates[index];

            results[index].id = update.id;
            results[index].key = update.key;
            results[index].value = update.value;
            results[index].utcStartVote = update.utcStartVote;
            results[index].utcEndVote = update.utcEndVote;
            results[index].totalApproved = update.totalApproved;
            results[index].totalUnapproved = update.totalUnapproved;
            results[index].isFinished = update.isFinished;
        }
        return results;
    }

    function getLastUpdate(Updates storage updates) internal view returns (Update memory) {
        Update memory result;
        Update storage update = updates.updates[updates.counter - 1];
                    
        result.id = update.id;
        result.key = update.key;
        result.value = update.value;
        result.utcStartVote = update.utcStartVote;
        result.utcEndVote = update.utcEndVote;
        result.totalApproved = update.totalApproved;
        result.totalUnapproved = update.totalUnapproved;
        result.isFinished = update.isFinished;
        return result;
    }

    /////////
    // Update View
    /////////

    function hasVoted(Update storage update, Updates storage updates, address _checkAddress) internal view returns (bool) {
        return updates.participators[update.id][_checkAddress] == _checkAddress;
    }

    function voteInProgress(Update storage update) internal view returns (bool) {
        return update.utcStartVote < block.timestamp
            && update.utcEndVote > block.timestamp;
    }

    function voteFinished(Update storage update) internal view returns (bool) {
        return update.utcStartVote < block.timestamp
            && update.utcEndVote < block.timestamp;
    }

    /////////
    // Updates Functions
    /////////

    function add(Updates storage updates, string calldata _key, address _value, uint256 _utcStartVote, uint256 _utcEndVote) internal {
        unchecked {
            uint256 id = updates.counter++;
            
            updates.updates[id].id = id;
            updates.updates[id].key = _key;
            updates.updates[id].value = _value;
            updates.updates[id].utcStartVote = _utcStartVote;
            updates.updates[id].utcEndVote = _utcEndVote;
            updates.updates[id].totalApproved = 0;
            updates.updates[id].totalUnapproved = 0;
            updates.updates[id].isFinished = false;
        }
    }

    /////////
    // Update Functions
    /////////

    function vote(Update storage update, Updates storage updates, address _from, uint256 _votes, bool _approved) internal {
        unchecked {
            if (_approved) {
                update.totalApproved += _votes;
            } else {
                update.totalUnapproved += _votes;
            }
            updates.participators[update.id][_from] = _from;
        }
    }

    function setFinished(Update storage update, bool _finished) internal {
        unchecked {
            update.isFinished = _finished;
        }
    }

    /**
     * @dev Returns an `UpdatesSlot` with member `value` located at `slot`.
     */
    function getUpdatesSlot(bytes32 slot) internal pure returns (UpdatesSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}