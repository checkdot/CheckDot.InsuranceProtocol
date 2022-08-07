// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelProducts {

    struct Product {
        uint256 id;
        string title;
        string URI;
        ProductStatus status;
        uint256 basePremiumInPercentPerDay;
        uint256 cumulativePremiumInPercentPerDay;
        uint256 utcProductStartDate;
        uint256 utcProductEndDate;
        uint256 minCoverInDays;
        uint256 maxCoverInDays;
        address[] coverCurrencies;
    }

    enum ProductStatus {
        NotSet,       // 0 |
        Active,       // 1 ===|
        Paused,       // 2 ===|
        Canceled      // 3 |
    }

    function coverCurrencyExists(Product storage product, address _currency) internal view returns (bool) {
        bool doesProductContainCurrency = false;
    
        for (uint256 i = 0; i < product.coverCurrencies.length; i++) {
            if (product.coverCurrencies[i] == _currency) {
                doesProductContainCurrency = true;
                break;
            }
        }
        return doesProductContainCurrency;
    }
}