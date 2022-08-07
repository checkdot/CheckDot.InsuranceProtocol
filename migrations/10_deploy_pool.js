const CheckDotPoolFactory = artifacts.require('CheckDotPoolFactory');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(CheckDotPoolFactory);
};