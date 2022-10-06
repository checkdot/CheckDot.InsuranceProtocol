const CheckDotInsuranceCovers = artifacts.require('CheckDotInsuranceCovers');

const UpgradableCheckDotInsuranceProducts = artifacts.require('UpgradableCheckDotInsuranceProducts');
const UpgradableCheckDotInsuranceCovers = artifacts.require('UpgradableCheckDotInsuranceCovers');
const UpgradableCheckDotInsuranceCalculator = artifacts.require('UpgradableCheckDotInsuranceCalculator');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceCovers.deployed();
    const indexFunctional = await CheckDotInsuranceCovers.deployed();

    console.log("Proxy", proxy.address);
    console.log("CheckDotPoolFactory", indexFunctional.address);

    const _dataInsuranceStore = web3.eth.abi.encodeParameters(['address', 'address'], [
        (await UpgradableCheckDotInsuranceProducts.deployed()).address,
        (await UpgradableCheckDotInsuranceCalculator.deployed()).address
    ]);

    await proxy.upgrade(indexFunctional.address, _dataInsuranceStore);
};