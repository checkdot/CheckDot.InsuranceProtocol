const UpgradableCheckDotInsuranceRiskDataCalculator = artifacts.require('UpgradableCheckDotInsuranceRiskDataCalculator');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(UpgradableCheckDotInsuranceRiskDataCalculator);
};