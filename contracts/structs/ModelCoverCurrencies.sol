// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelCoverCurrencies {

    struct CoverCurrency {
        address tokenAddress;
        uint256 minCoverAmount;
        uint256 maxCoverAmount;
    }

}