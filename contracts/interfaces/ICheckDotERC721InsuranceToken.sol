// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../structs/ModelCovers.sol";

/**
 * @title ICheckDotERC721InsuranceToken
 * @author Jeremy Guyet (@jguyet)
 * @dev See {CheckDotERC721InsuranceToken}.
 */
interface ICheckDotERC721InsuranceToken {

    function initialize(bytes memory _data) external;

    // covers
    function mintInsuranceToken(uint256 _productId, address _coveredAddress, uint256 _insuranceTermInDays, uint256 _premiumAmount, address _coveredCurrency, uint256 _coveredAmount, string calldata _uri) external payable returns (uint256);
    function revokeExpiredCovers() external payable;

    // claim
    function claim(uint256 _tokenId, uint256 _claimAmount, string calldata _claimProperties) external;
    function teamApproveClaim(uint256 _tokenId, uint256 _claimId, bool approved, string calldata _claimAdditionnalProperties) external;
    function payoutClaim(uint256 _tokenId) external;

    function getStoreAddress() external view returns (address);

    function getInsuranceProtocolAddress() external view returns (address);

    function getInsurancePoolFactoryAddress() external view returns (address);

    function getCover(uint256 _id) external view returns (ModelCovers.Cover memory);

    function coverIsAvailable(uint256 tokenId) external view returns (bool);

    function getTotalCoveredAmountFromCurrency(address _currency) external view returns (uint256);

    //////////
    // ERC721 Views
    //////////

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}