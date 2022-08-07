// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelPools {

    struct Pool {
        address token;
        address poolAddress;
    }

    struct PoolWithReserve {
        address token;
        address poolAddress;
        uint256 reserve;
    }

}