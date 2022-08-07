// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelInsurances {

    struct Insurance {
        uint256 id;
        string  uri;
        address coveredAddress;
        uint256 utcStart;
        uint256 utcEnd;
        uint256 coveredAmount;
        address coveredCurrency;
        uint256 premiumAmount;
        InsuranceStatus status;

        // claim
        string  claimProperties;
        uint256 claimPayout;
        uint256 claimUtcPayoutDate;
    }

    enum InsuranceStatus {
        NotSet,         // 0 |
        Active,         // 1 ===|
        ClaimProcedure, // 2 ===|
        Canceled        // 3 |
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