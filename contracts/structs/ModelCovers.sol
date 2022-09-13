// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelCovers {

    struct Cover {
        uint256 id;
        uint256 productId;
        string  uri;
        address coveredAddress;
        uint256 utcStart;
        uint256 utcEnd;
        uint256 coveredAmount;
        address coveredCurrency;
        uint256 premiumAmount;
        CoverStatus status;

        // claim
        uint256 claimId;
        string  claimProperties;
        string  claimAdditionnalProperties;
        uint256 claimPayout;
        uint256 claimUtcPayoutDate;
    }

    enum CoverStatus {
        NotSet,           // 0 |
        Active,           // 1 ===|
        ClaimApprobation, // 2 ===|
        Claim,            // 3 ===|
        Canceled          // 4 |
    }

    // modifier insuranceValidForClaim(bytes32 _policyId) {
    //     require(policies[_policyId].owner != address(0), "Owner is not valid");       
    //     require(policies[_policyId].payout == 0, "Payout already done");
    //     require(policies[_policyId].status != PolicyStatus.ClaimProcedure, "Payout already in progress");
    //     require(policies[_policyId].calculatedPayout != 0, "Policy is not set");
    //     require(policies[_policyId].utcEnd > block.timestamp, "Policy has ended");
    //     _;
    // }

    // modifier insuranceValidForPayout(bytes32 _policyId) {
    //     require(policies[_policyId].owner != address(0), "Owner is not valid");       
    //     require(policies[_policyId].payout == 0, "Payout already done");
    //     require(policies[_policyId].status == PolicyStatus.ClaimProcedure, "Payout is not set");
    //     require(policies[_policyId].calculatedPayout != 0, "Policy is not set");
    //     _;
    // }

}