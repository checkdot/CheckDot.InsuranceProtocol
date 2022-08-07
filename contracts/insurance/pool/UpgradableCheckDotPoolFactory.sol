// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../../../CheckDot.DAOProxyContract/contracts/Proxy.sol";

contract UpgradableCheckDotPoolFactory is Proxy {
    constructor(address _cdtGouvernanceAddress) Proxy(_cdtGouvernanceAddress) { }
}