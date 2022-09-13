const UpgradableCheckDotInsuranceStore = artifacts.require('UpgradableCheckDotInsuranceStore');
const CheckDotInsuranceStore = artifacts.require('CheckDotInsuranceStore');
const CheckDotPoolFactory = artifacts.require('CheckDotPoolFactory');
const CheckDotInsuranceProtocol = artifacts.require('CheckDotInsuranceProtocol');

const UpgradableCheckDotInsuranceProtocol = artifacts.require('UpgradableCheckDotInsuranceProtocol');
const UpgradableCheckDotPoolFactory = artifacts.require('UpgradableCheckDotPoolFactory');
const UpgradableCheckDotERC721InsuranceToken = artifacts.require('UpgradableCheckDotERC721InsuranceToken');
const UpgradableCheckDotInsuranceRiskDataCalculator = artifacts.require('UpgradableCheckDotInsuranceRiskDataCalculator');


module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceProtocol.deployed();
    const protocol = await CheckDotInsuranceProtocol.at(proxy.address);
    console.log("Proxy", proxy.address);

    console.log(await protocol.revokeExpiredCovers());
};