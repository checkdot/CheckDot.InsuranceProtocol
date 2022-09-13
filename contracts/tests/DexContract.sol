// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DexContract {
    constructor() { }

    function getAmountsOut(uint256 amountIn, address[] calldata path) external pure returns (uint256[] memory amounts) {
        uint256[] memory results = new uint256[](2);
        if (path[0] == address(0x79deC2de93f9B16DD12Bc6277b33b0c81f4D74C7)) { // CDT
            results[0] = 1 ether;
            results[1] = 14957819785882239;
        } else {
            results[0] = 1 ether;
            results[1] = 1 ether;
        }
        return results;
    }
}