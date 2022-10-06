const CheckDotInsuranceProducts = artifacts.require('CheckDotInsuranceProducts');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(CheckDotInsuranceProducts);
};