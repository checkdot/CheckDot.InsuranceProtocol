// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDex {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}