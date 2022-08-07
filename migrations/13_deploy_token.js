const CheckDotERC721InsuranceToken = artifacts.require('CheckDotERC721InsuranceToken');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    await deployer.deploy(CheckDotERC721InsuranceToken);
};