const CheckDotPoolFactory = artifacts.require('CheckDotPoolFactory');

const UpgradableCheckDotInsuranceProtocol = artifacts.require('UpgradableCheckDotInsuranceProtocol');
const UpgradableCheckDotPoolFactory = artifacts.require('UpgradableCheckDotPoolFactory');
const UpgradableCheckDotERC721InsuranceToken = artifacts.require('UpgradableCheckDotERC721InsuranceToken');
const UpgradableCheckDotInsuranceRiskDataCalculator = artifacts.require('UpgradableCheckDotInsuranceRiskDataCalculator');


module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotPoolFactory.deployed();
    const factory = await CheckDotPoolFactory.at(proxy.address);
    console.log("Proxy", proxy.address);

    await factory.createPool("0x55d398326f99059ff775485246999027b3197955");// USDT
    // await factory.createPool("0xe9e7cea3dedca5984780bafc599bd69add087d56");// BUSD
};