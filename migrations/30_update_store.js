const UpgradableCheckDotInsuranceStore = artifacts.require('UpgradableCheckDotInsuranceStore');
const CheckDotInsuranceStore = artifacts.require('CheckDotInsuranceStore');

const UpgradableCheckDotInsuranceProtocol = artifacts.require('UpgradableCheckDotInsuranceProtocol');
const UpgradableCheckDotPoolFactory = artifacts.require('UpgradableCheckDotPoolFactory');
const UpgradableCheckDotERC721InsuranceToken = artifacts.require('UpgradableCheckDotERC721InsuranceToken');
const UpgradableCheckDotInsuranceRiskDataCalculator = artifacts.require('UpgradableCheckDotInsuranceRiskDataCalculator');


module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceStore.deployed();
    const insuranceStore = await CheckDotInsuranceStore.at(proxy.address);
    console.log("Proxy", proxy.address);

    const protocols = [
        // ["INSURANCE_PROTOCOL", UpgradableCheckDotInsuranceProtocol],
        // ["INSURANCE_POOL_FACTORY", UpgradableCheckDotPoolFactory],
        // ["INSURANCE_TOKEN", UpgradableCheckDotERC721InsuranceToken],
        ["INSURANCE_RISK_DATA_CALCULATOR", UpgradableCheckDotInsuranceRiskDataCalculator]
    ];

    for (let i = 0; i < protocols.length; i++) {
        const p = await protocols[i][1].deployed();

        await insuranceStore.updateAddress(protocols[i][0], p.address);
    }
};