const UpgradableCheckDotERC721InsuranceToken = artifacts.require('UpgradableCheckDotERC721InsuranceToken');
const CheckDotERC721InsuranceToken = artifacts.require('CheckDotERC721InsuranceToken');
const UpgradableCheckDotInsuranceStore = artifacts.require('UpgradableCheckDotInsuranceStore');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotERC721InsuranceToken.deployed();
    const protocol = await CheckDotERC721InsuranceToken.at(proxy.address);

    console.log("Proxy", proxy.address);

    console.log(await protocol.revokeExpiredCovers());
};