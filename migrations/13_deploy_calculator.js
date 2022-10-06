const CheckDotInsuranceCalculator = artifacts.require('CheckDotInsuranceCalculator');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(CheckDotInsuranceCalculator);
};