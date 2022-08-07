const UpgradableCheckDotERC721InsuranceToken = artifacts.require('UpgradableCheckDotERC721InsuranceToken');
const CheckDotERC721InsuranceToken = artifacts.require('CheckDotERC721InsuranceToken');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotERC721InsuranceToken.deployed();
    const indexFunctional = await CheckDotERC721InsuranceToken.deployed();

    console.log("Proxy", proxy.address);
    console.log("CheckDotERC721InsuranceToken", indexFunctional.address);

    const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 3400;
    const startUTC = `${currentBlockTimeStamp.toFixed(0)}`;
    const endUTC = `${(currentBlockTimeStamp + 86400).toFixed(0)}`;

    console.log(startUTC, endUTC);

    await proxy.upgrade(indexFunctional.address, startUTC, endUTC);
};