const UpgradableCheckDotInsuranceRiskDataCalculator = artifacts.require('UpgradableCheckDotInsuranceRiskDataCalculator');
const CheckDotInsuranceRiskDataCalculator = artifacts.require('CheckDotInsuranceRiskDataCalculator');
const UpgradableCheckDotInsuranceStore = artifacts.require('UpgradableCheckDotInsuranceStore');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const store = await UpgradableCheckDotInsuranceStore.deployed();
    const proxy = await UpgradableCheckDotInsuranceRiskDataCalculator.deployed();
    const indexFunctional = await CheckDotInsuranceRiskDataCalculator.deployed();

    console.log("Proxy", proxy.address);
    console.log("CheckDotInsuranceRiskDataCalculator", indexFunctional.address);

    const CDTGouvernanceTokenAddress = "0x0cbd6fadcf8096cc9a43d90b45f65826102e3ece";

    const _dataInsuranceStoreWithDex = web3.eth.abi.encodeParameters(['address', 'address', 'address', 'address', 'address'], [
        store.address,
        CDTGouvernanceTokenAddress,
        "0x10ED43C718714eb63d5aA57B78B54704E256024E", // Pcswp v2
        "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", // BUSD
        "0x55d398326f99059fF775485246999027B3197955" // USDT
    ]);

    await proxy.upgrade(indexFunctional.address, _dataInsuranceStoreWithDex);
};