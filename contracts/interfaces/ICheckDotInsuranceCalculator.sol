// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title ICheckDotInsuranceRiskDataCalculator
 * @author Jeremy Guyet (@jguyet)
 * @dev See {CheckDotInsuranceRiskDataCalculator}.
 */
interface ICheckDotInsuranceCalculator {

    function initialize(bytes memory _data) external;

    function getTotalCoveredAmountFromCurrency(address _currency) external view returns (uint256);

    function coverIsSolvable(uint256 /*_productId*/, uint256 _productRiskRatio, address _coverCurrency, uint256 _newCoverAmount) external view returns (bool);

    function getSolvabilityRatio() external view returns (uint256);

    function getSCRPercent() external view returns (uint256);

    function getSCRSize() external view returns (uint256);

    function getSolvability() external view returns(uint256, uint256, uint256);

    function getClaimPrice(address _coveredCurrency, uint256 _claimAmount) external view returns (uint256);

    function convertCost(uint256 _costIn, address _in, address _out) external view returns (uint256);

    function convertCostPassingPerWrappedToken(uint256 _costIn, address _in, address _out) external view returns (uint256);

    function getTokenPriceInUSD(address _token) external view returns (uint256);

    function getTokenPriceOut(address _in, address _out) external view returns (uint256);

    function getStoreAddress() external view returns (address);

    function getInsuranceProtocolAddress() external view returns (address);

    function getInsurancePoolFactoryAddress() external view returns (address);

    function getInsuranceTokenAddress() external view returns (address);
}