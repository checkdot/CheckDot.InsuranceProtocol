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
        // address[] coverCurrencies;
        // address[] coverCurrenciesPoolAddresses;
        // uint256[] minCoverCurrenciesAmounts;
        // uint256[] maxCoverCurrenciesAmounts;
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
        // address[] coverCurrencies;
        // address[] coverCurrenciesPoolAddresses;
        // uint256[] minCoverCurrenciesAmounts;
        // uint256[] maxCoverCurrenciesAmounts;
        // uint256[] cumulativePremiumInPercents;
        // uint256[] coverCurrenciesCoveredAmounts;
        // int256[] coverCurrenciesCapacities;
        // bool[] coverCurrenciesEnabled;
    }

    // function coverCurrencyExists(Product storage product, address _currency) internal view returns (bool) {
    //     bool doesProductContainCurrency = false;
    
    //     for (uint256 i = 0; i < product.coverCurrencies.length; i++) {
    //         if (product.coverCurrencies[i] == _currency) {
    //             doesProductContainCurrency = true;
    //             break;
    //         }
    //     }
    //     return doesProductContainCurrency;
    // }

    // function getCoverCurrencyIndex(Product storage product, address _currency) internal view returns (uint256) {
    //     uint256 index = 0;
    
    //     for (uint256 i = 0; i < product.coverCurrencies.length; i++) {
    //         if (product.coverCurrencies[i] == _currency) {
    //             index = i;
    //             break;
    //         }
    //     }
    //     return index;
    // }

    // function getCoverCurrencyPoolAddress(Product storage product, address _currency) internal view returns (address) {
    //     uint256 index = getCoverCurrencyIndex(product, _currency);
    //     return product.coverCurrenciesPoolAddresses[index];
    // }
}