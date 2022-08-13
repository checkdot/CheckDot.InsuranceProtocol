// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelClaims {

    struct Claim {
        uint256 id;
        string  properties;
        address coveredAddress;
        address poolAddress;
        address coveredCurrency;
        uint256 amount;
        uint256 utcStartVote;
        uint256 utcEndVote;
        uint256 totalApproved;
        uint256 totalUnapproved;
        ClaimStatus status;
    }

    enum ClaimStatus {
        NotSet,           // 0 |
        Approbation,      // 1 |
        Vote,             // 2 |
        Paid,             // 3 |
        Canceled          // 4 |
    }

    struct ClaimWithParticipators {
        Claim claim;
        mapping(address => address) participators;
    }

}