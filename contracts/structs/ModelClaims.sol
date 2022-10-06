// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelClaims {

    struct Claim {
        mapping(string => address) a;
        mapping(string => uint256) n;
        mapping(string => string) s;
        // uint256 id;
        // uint256 coverId;
        // uint256 productId;
        // string  properties;
        // string  additionnalProperties;
        // address coveredAddress;
        // address poolAddress;
        // address coveredCurrency;
        // uint256 amount;
        // uint256 rewardsInCDT;
        // uint256 alreadyRewardedAmount;
        // uint256 utcStartVote;
        // uint256 utcEndVote;
        // uint256 totalApproved;
        // uint256 totalUnapproved;
        // ClaimStatus status;
    }

    struct Vote {
        address voter;
        uint256 totalApproved;
        uint256 totalUnapproved;
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
        mapping(address => Vote) participators;
    }

}