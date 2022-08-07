// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../utils/StoreUpdates.sol";

/**
 * @title ICheckDotInsuranceStore
 * @author Jeremy Guyet (@jguyet)
 * @dev See {CheckDotInsuranceStore}.
 */
interface ICheckDotInsuranceStore {

    function initialize() external payable;

    function updateAddress(string calldata _key, address _newAddress, uint256 _utcStartVote, uint256 _utcEndVote) external payable;

    function voteUpdateCounting() external payable;

    function voteUpdate(bool approve) external payable;

    function getAllUpdates() external view returns (StoreUpdates.Update[] memory);

    function getLastUpdate() external view returns (StoreUpdates.Update memory);

    function getAddress(string calldata _key) external view returns (address);
}