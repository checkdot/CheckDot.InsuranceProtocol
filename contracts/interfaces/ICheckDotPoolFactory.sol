// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../structs/ModelPools.sol";
import "../structs/ModelClaims.sol";

interface ICheckDotPoolFactory {

    function setStore(address _store) external;

    function createPool(address _token) external returns (address pool);

    function contribute(address _token, address _from, uint256 _amountOfTokens) external;

    function uncontribute(address _token, address _to, uint256 _amountOfliquidityTokens) external;

    function claim(address _token, uint256 _id, uint256 _amount, address _claimer) external returns (bool);

    function payout(uint256 _id) external returns (bool approved);

    function vote(uint256 _id, bool approve) external;

    //////////
    // Views
    //////////

    function getPools(int256 page, int256 pageSize) external view returns (ModelPools.PoolWithReserve[] memory);

    function getPool(address _token) external view returns (ModelPools.PoolWithReserve memory);

    function getPoolsLength() external view returns (uint256);

    function poolExists(address _token) external view returns(bool);

    function poolAddress(address _token) external view returns(address);

    function getClaim(uint256 _id) external view returns (ModelClaims.Claim memory);

    function getClaims(int256 page, int256 pageSize) external view returns (ModelClaims.Claim[] memory);

    function getClaimsLength() external view returns (uint256);

    function getStore() external view returns (address);
}