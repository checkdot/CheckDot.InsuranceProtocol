const CheckDotInsuranceCalculator = artifacts.require('CheckDotInsuranceCalculator');

const UpgradableCheckDotInsuranceProducts = artifacts.require('UpgradableCheckDotInsuranceProducts');
const UpgradableCheckDotInsuranceCovers = artifacts.require('UpgradableCheckDotInsuranceCovers');
const UpgradableCheckDotInsuranceCalculator = artifacts.require('UpgradableCheckDotInsuranceCalculator');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceCalculator.deployed();
    const indexFunctional = await CheckDotInsuranceCalculator.deployed();

    console.log("Proxy", proxy.address);
    console.log("CheckDotInsuranceRiskDataCalculator", indexFunctional.address);

    const _dataInsuranceStoreWithDex = web3.eth.abi.encodeParameters(['address', 'address', 'address', 'address', 'address', 'address', 'address'], [
        (await UpgradableCheckDotInsuranceProducts.deployed()).address,
        (await UpgradableCheckDotInsuranceCovers.deployed()).address,
        "0x0cbd6fadcf8096cc9a43d90b45f65826102e3ece", // CDTGouvernanceTokenAddress
        "0x10ED43C718714eb63d5aA57B78B54704E256024E", // Pcswp v2
        "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", // BUSD
        "0x55d398326f99059fF775485246999027B3197955" // USDT
    ]);

    await proxy.upgrade(indexFunctional.address, _dataInsuranceStoreWithDex);
};