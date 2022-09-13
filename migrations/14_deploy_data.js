const CheckDotInsuranceRiskDataCalculator = artifacts.require('CheckDotInsuranceRiskDataCalculator');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(CheckDotInsuranceRiskDataCalculator);
};