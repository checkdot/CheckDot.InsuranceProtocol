// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title IDAOProxy
 * @author Jeremy Guyet (@jguyet)
 * @dev See {UpgradableProxyDAO}.
 */
interface IDAOProxy {

    function getGovernance() external view returns (address);
}
