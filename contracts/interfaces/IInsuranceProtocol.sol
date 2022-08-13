// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../structs/ModelProducts.sol";

/**
 * @dev Interface of the Insurance Protocol
 */
interface IInsuranceProtocol {

    function initialize() external payable;
    function getStoreAddress() external view returns (address);
    function getPoolFactoryAddress() external view returns (address);
    function getInsuranceTokenAddress() external view returns (address);
    function getPremiumCalculatorAddress() external view returns (address);

    //////////
    // Actions
    //////////

    function createProduct(uint256 _utcProductStartDate, uint256 _utcProductEndDate, uint256 _minCoverInDays, uint256 _maxCoverInDays, uint256 _basePremiumInPercentPerDay, string calldata _uri, string calldata _title, address[] calldata _coverCurrencies) external;
    function buy(uint256 _productId, uint256 _coverAmount, address _coveredCurrency, uint256 _durationInDays, bool _useCDTs) external payable;          
    function claim(uint256 _insuranceTokenId, uint256 _claimAmount) external payable;
    function payout(uint256 _insuranceTokenId) external payable;

    //////////
    // Views
    //////////

    function getProducts(uint256 _page, uint256 _size) external view returns (ModelProducts.Product[] memory);

    //////////
    // Updates
    //////////

    function pauseProduct(uint256 _productId) external;
    function activeProduct(uint256 _productId) external;
    function cancelProduct(uint256 _productId) external;
    function updateProduct(uint256 _productId, string calldata _title, string calldata _description, uint256 _premiumInPercentPerDay, uint256 _utcProductStartDate, uint256 _utcProductEndDate, uint256 _minCoverInDays, uint256 _maxCoverInDays) external;
}