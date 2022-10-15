// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct PoolInformations {
    address token;
    uint256 totalSupply; // LP token
    uint256 reserve;
}

struct CoverInformations {
    // cover slots
    uint256 id;
    uint256 productId;
    string  uri;
    address coveredAddress;
    uint256 utcStart;
    uint256 utcEnd;
    uint256 coveredAmount;
    address coveredCurrency;
    uint256 premiumAmount;
    uint256 status;
    // claim slots
    string  claimProperties;
    string  claimAdditionnalProperties;
    uint256 claimAmount;
    uint256 claimPayout;
    uint256 claimUtcPayoutDate;
    uint256 claimRewardsInCDT;
    uint256 claimAlreadyRewardedAmount;
    uint256 claimUtcStartVote;
    uint256 claimUtcEndVote;
    uint256 claimTotalApproved;
    uint256 claimTotalUnapproved;
    // others slots
}

struct Vote {
    address voter;
    uint256 totalApproved;
    uint256 totalUnapproved;
}

interface ICheckDotInsuranceCovers {

    function getVersion() external pure returns (uint256);
    function getInsuranceProductsAddress() external view returns (address);
    function getInsuranceCalculatorAddress() external view returns (address);

    //////////
    // Actions
    //////////

    function contribute(address _token, address _from, uint256 _amountOfTokens) external;
    function uncontribute(address _token, address _to, uint256 _amountOfliquidityTokens) external;
    function sync(address _token) external;
    function claim(uint256 _insuranceTokenId, uint256 _claimAmount, string calldata _claimProperties) external returns (uint256);
    function teamApproveClaim(uint256 _insuranceTokenId, bool _approved, string calldata _additionnalProperties) external;
    function voteForClaim(uint256 _insuranceTokenId, bool _approved) external;
    function payoutClaim(uint256 _insuranceTokenId) external;

    //////////
    // Views
    //////////

    function getClaimPrice(address _coveredCurrency, uint256 _claimAmount) external view returns (uint256);
    function getNextVoteRewards(uint256 _insuranceTokenId) external view returns (uint256);
    function getVoteOf(uint256 _insuranceTokenId, address _addr) external view returns (Vote memory);
    function getPools(int256 page, int256 pageSize) external view returns (PoolInformations[] memory);
    function getPool(address _token) external view returns (PoolInformations memory);
    function getPoolsLength() external view returns (uint256);
    function getPoolContributionInformations(address _token, address _staker) external view returns (uint256, bool, uint256, uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getCoverIdsByOwner(address _owner) external view returns (uint256[] memory);
    function getCoversByOwner(address _owner) external view returns (CoverInformations[] memory);
    function getCover(uint256 tokenId) external view returns (CoverInformations memory);
    function getLightCoverInformation(uint256 tokenId) external view returns (address, uint256, uint256);
    function getCoversCount() external view returns (uint256);

    //////////
    // onlyInsuranceProducts
    //////////

    function mintInsuranceToken(uint256 _productId, address _coveredAddress, uint256 _insuranceTermInDays, uint256 _premiumAmount, address _coveredCurrency, uint256 _coveredAmount, string calldata _uri) external returns (uint256);
    function addInsuranceProtocolFees(address _token, address _from) external;

    //////////
    // Owner Actions
    //////////

    function createPool(address _token) external;
    function initialize(bytes memory _data) external; // called from proxy

}