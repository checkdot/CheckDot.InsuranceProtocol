const UpgradableCheckDotInsuranceProtocol = artifacts.require('UpgradableCheckDotInsuranceProtocol');
const CheckDotInsuranceProtocol = artifacts.require('CheckDotInsuranceProtocol');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceProtocol.deployed();
    const indexFunctional = await CheckDotInsuranceProtocol.deployed();

    console.log("Proxy", proxy.address);
    console.log("CheckDotInsuranceProtocol", indexFunctional.address);

    const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 3400;
    const startUTC = `${currentBlockTimeStamp.toFixed(0)}`;
    const endUTC = `${(currentBlockTimeStamp + 86400).toFixed(0)}`;

    console.log(startUTC, endUTC);

    await proxy.upgrade(indexFunctional.address, startUTC, endUTC);
};