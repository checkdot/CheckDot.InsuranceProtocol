// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP with CheckDotPool.
 */
interface ICheckDotPool {
    function initialize(address _token) external;
    function factory() external view returns (address);
    function token() external view returns (address);
    function getReserves() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount);
    function sync() external;
    function refund(address to, uint256 amount) external;
}