const UpgradableCheckDotInsuranceCalculator = artifacts.require('UpgradableCheckDotInsuranceCalculator');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(UpgradableCheckDotInsuranceCalculator);
};