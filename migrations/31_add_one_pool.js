const CheckDotInsuranceCovers = artifacts.require('CheckDotInsuranceCovers');

const UpgradableCheckDotInsuranceProducts = artifacts.require('UpgradableCheckDotInsuranceProducts');
const UpgradableCheckDotInsuranceCovers = artifacts.require('UpgradableCheckDotInsuranceCovers');
const UpgradableCheckDotInsuranceCalculator = artifacts.require('UpgradableCheckDotInsuranceCalculator');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceCovers.deployed();
    const insuranceCovers = await CheckDotInsuranceCovers.at(proxy.address);
    console.log("Proxy", proxy.address);

    await insuranceCovers.createPool("0x55d398326f99059ff775485246999027b3197955");// USDT
    // await insuranceCovers.createPool("0xe9e7cea3dedca5984780bafc599bd69add087d56");// BUSD
};