const CheckDotInsuranceStore = artifacts.require('CheckDotInsuranceStore');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(CheckDotInsuranceStore);
};