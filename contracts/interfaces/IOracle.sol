// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title IOracle
 * @author Jeremy Guyet (@jguyet)
 * @dev Gives the price of an `_in` token against an `_out` token from Dexs
 */
interface IOracle {
    function convertCost(uint256 _costIn, address _in, address _out) external view returns (uint256);
    function convertCostPassingPerWrappedToken(uint256 _costIn, address _in, address _out) external view returns (uint256);
    function getClaimPrice(address _coveredCurrency, uint256 _claimAmount) external view returns (uint256);
}