const UpgradableCheckDotInsuranceProtocol = artifacts.require('UpgradableCheckDotInsuranceProtocol');
const CheckDotInsuranceProtocol = artifacts.require('CheckDotInsuranceProtocol');
const UpgradableCheckDotInsuranceStore = artifacts.require('UpgradableCheckDotInsuranceStore');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const store = await UpgradableCheckDotInsuranceStore.deployed();
    const proxy = await UpgradableCheckDotInsuranceProtocol.deployed();
    const indexFunctional = await CheckDotInsuranceProtocol.deployed();

    console.log("Proxy", proxy.address);
    console.log("CheckDotInsuranceProtocol", indexFunctional.address);

    // const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 3400;
    // const startUTC = `${currentBlockTimeStamp.toFixed(0)}`;
    // const endUTC = `${(currentBlockTimeStamp + 86400).toFixed(0)}`;

    // console.log(startUTC, endUTC);

    const _dataInsuranceStore = web3.eth.abi.encodeParameters(['address'], [
        store.address
    ]);

    await proxy.upgrade(indexFunctional.address, _dataInsuranceStore);
};