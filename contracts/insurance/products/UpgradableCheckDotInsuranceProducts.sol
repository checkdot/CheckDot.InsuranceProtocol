// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../DaoProxy/ProxyDAO.sol";

contract UpgradableCheckDotInsuranceProducts is ProxyDAO {
    constructor(address _cdtGouvernanceAddress) ProxyDAO(_cdtGouvernanceAddress) { }
}