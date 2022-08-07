// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ModelClaims {

    struct Claim {
        uint256 id;
        address coveredAddress;
        address pool;
        address coveredCurrency;
        uint256 amount;
        uint256 utcStartVote;
        uint256 utcEndVote;
        uint256 totalApproved;
        uint256 totalUnapproved;
        bool isFinished;
    }

    struct ClaimWithParticipators {
        Claim claim;
        mapping(address => address) participators;
    }

}