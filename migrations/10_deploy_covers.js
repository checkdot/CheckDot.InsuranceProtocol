const CheckDotInsuranceCovers = artifacts.require('CheckDotInsuranceCovers');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(CheckDotInsuranceCovers);
};