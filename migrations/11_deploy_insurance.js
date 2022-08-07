const CheckDotInsuranceProtocol = artifacts.require('CheckDotInsuranceProtocol');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(CheckDotInsuranceProtocol);
};