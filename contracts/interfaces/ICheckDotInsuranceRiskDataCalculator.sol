// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title ICheckDotInsuranceStore
 * @author Jeremy Guyet (@jguyet)
 * @dev See {CheckDotInsuranceStore}.
 */
interface ICheckDotInsuranceRiskDataCalculator {

    function addCoverAmountByCurrency(address _coverCurrency, uint256 _amount) external;

    function subCoverAmountByCurrency(address _coverCurrency, uint256 _amount) external;

    function coverIsSolvable(uint256 _productRiskRatio, address _coverCurrency, uint256 _newCoverAmount) external view returns (bool);

    function getActiveCoverAmountByCurrency(address _coverCurrency) external view returns (uint256);

    function getCostInCDT(uint256 _costInUSD, address _token) external view returns (uint256);

    function getStoreAddress() external view returns (address);

    function getInsuranceProtocolAddress() external view returns (address);

    function getInsurancePoolFactoryAddress() external view returns (address);

    function getInsuranceTokenAddress() external view returns (address);
}