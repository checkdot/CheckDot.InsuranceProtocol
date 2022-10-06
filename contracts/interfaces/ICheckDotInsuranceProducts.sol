// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct ProductInformations {
    uint256 id;
    string  name;
    string  riskType;
    string  uri;
    uint256 status;
    uint256 riskRatio;
    uint256 basePremiumInPercent;
    uint256 minCoverInDays;
    uint256 maxCoverInDays;
}

/**
 * @dev Interface of the Insurance Products Contract
 */
interface ICheckDotInsuranceProducts {

    function getInsuranceCoversAddress() external view returns (address);
    function getInsuranceCalculatorAddress() external view returns (address);

    //////////
    // Actions
    //////////

    function buyCover(uint256 _productId, address _coveredAddress, uint256 _coveredAmount, address _coverCurrency, uint256 _durationInDays, address _payIn) external payable;
    function isValidBuy(uint256 _productId, address _coveredAddress, uint256 _coveredAmount, address _coverCurrency, uint256 _durationInDays, address _payIn) external view returns (bool);

    //////////
    // Views
    //////////

    function getCoverCost(uint256 _productId, address _coverCurrency, uint256 _coveredAmount, uint256 _durationInDays) external view returns (uint256);
    function getProductLength() external view returns (uint256);
    function getProductDetails(uint256 _id) external view returns (ProductInformations memory);
    function getCoverCurrencyDetails(address _coverCurrency) external view returns (uint256, uint256, int256, uint256);

    //////////
    // Owner Actions
    //////////

    function createProduct(uint256 _id, bytes memory _data) external;
    function pauseProduct(uint256 _productId) external;
    function activeProduct(uint256 _productId) external;
    function cancelProduct(uint256 _productId) external;
    function initialize(bytes memory _data) external; // called from proxy
}