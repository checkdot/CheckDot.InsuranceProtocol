// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelPools {

    struct Pool {
        address token;
        uint256 totalSupply; // LP token
        uint256 reserve;
    }

}