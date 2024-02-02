const CheckDotInsuranceCovers = artifacts.require('CheckDotInsuranceCovers');
const CheckDotInsuranceProducts = artifacts.require('CheckDotInsuranceProducts');

const UpgradableCheckDotInsuranceProducts = artifacts.require('UpgradableCheckDotInsuranceProducts');
const UpgradableCheckDotInsuranceCovers = artifacts.require('UpgradableCheckDotInsuranceCovers');
const UpgradableCheckDotInsuranceCalculator = artifacts.require('UpgradableCheckDotInsuranceCalculator');


module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceProducts.deployed();
    const insuranceProducts = await CheckDotInsuranceProducts.at(proxy.address);
    console.log("Proxy", proxy.address);

    ///////////////////////
    const _id = 7;
    ///////////////////////

    await insuranceProducts.pauseProduct(_id);
};