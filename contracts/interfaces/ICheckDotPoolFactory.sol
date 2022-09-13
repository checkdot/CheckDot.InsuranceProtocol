// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../structs/ModelPools.sol";
import "../structs/ModelClaims.sol";

interface ICheckDotPoolFactory {

    function getInitCodePoolHash() external pure returns (bytes32);

    function setStore(address _store) external;

    function createPool(address _token) external returns (address pool);

    function contribute(address _token, address _from, uint256 _amountOfTokens) external;

    function uncontribute(address _token, address _to, uint256 _amountOfliquidityTokens) external;

    function mintInsuranceProtocolFees(address _token, address _from) external;

    function claim(uint256 _insuranceTokenId, uint256 _claimAmount, string calldata _claimProperties) external returns (uint256);
    
    function teamApproveClaim(uint256 claimId, bool approved, string calldata additionnalProperties) external;

    function voteForClaim(uint256 claimId, bool approved) external;

    function payoutClaim(uint256 claimId) external;

    //////////
    // Views
    //////////

    function getPools(int256 page, int256 pageSize) external view returns (ModelPools.PoolWithReserve[] memory);

    function getPool(address _token) external view returns (ModelPools.PoolWithReserve memory);

    function getPoolsLength() external view returns (uint256);

    function poolExists(address _token) external view returns(bool);

    function poolAddress(address _token) external view returns(address);

    function getStore() external view returns (address);
}