// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title ICheckDotInsuranceStore
 * @author Jeremy Guyet (@jguyet)
 * @dev See {CheckDotInsuranceStore}.
 */
interface ICheckDotInsuranceStore {

    function initialize() external;

    function updateAddress(string calldata _key, address _newAddress) external;

    function getAddress(string calldata _key) external view returns (address);
}