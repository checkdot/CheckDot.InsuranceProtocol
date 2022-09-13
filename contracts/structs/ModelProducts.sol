// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelProducts {

    struct Product {
        uint256 id;
        string name;
        string riskType;
        string URI;
        ProductStatus status;
        uint256 riskRatio;
        uint256 basePremiumInPercent;
        uint256 utcProductStartDate;
        uint256 utcProductEndDate;
        uint256 minCoverInDays;
        uint256 maxCoverInDays;
    }

    enum ProductStatus {
        NotSet,       // 0 |
        Active,       // 1 ===|
        Paused,       // 2 ===|
        Canceled      // 3 |
    }

    struct ProductWithDetails {
        uint256 id;
        string name;
        string URI;
        ProductStatus status;
        uint256 riskRatio;
        uint256 basePremiumInPercent;
        uint256 utcProductStartDate;
        uint256 utcProductEndDate;
        uint256 minCoverInDays;
        uint256 maxCoverInDays;
    }

}