const CheckDotPoolFactory = artifacts.require('CheckDotPoolFactory');

const UpgradableCheckDotInsuranceProtocol = artifacts.require('UpgradableCheckDotInsuranceProtocol');
const UpgradableCheckDotPoolFactory = artifacts.require('UpgradableCheckDotPoolFactory');
const UpgradableCheckDotERC721InsuranceToken = artifacts.require('UpgradableCheckDotERC721InsuranceToken');
const UpgradableCheckDotInsuranceRiskDataCalculator = artifacts.require('UpgradableCheckDotInsuranceRiskDataCalculator');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const insuranceProtocolProxy = await UpgradableCheckDotInsuranceProtocol.deployed();
    const insurancePoolFactoryProxy = await UpgradableCheckDotPoolFactory.deployed();
    const insuranceTokenProxy = await UpgradableCheckDotERC721InsuranceToken.deployed();
    const insuranceRiskDataCalculatorProxy = await UpgradableCheckDotInsuranceRiskDataCalculator.deployed();

    const proxy = await UpgradableCheckDotPoolFactory.deployed();
    const indexFunctional = await CheckDotPoolFactory.deployed();

    console.log("Proxy", proxy.address);
    console.log("CheckDotPoolFactory", indexFunctional.address);

    const _dataInsuranceStore = web3.eth.abi.encodeParameters(['address', 'address', 'address'], [
        insuranceProtocolProxy.address,
        insuranceTokenProxy.address,
        insuranceRiskDataCalculatorProxy.address
    ]);

    await proxy.upgrade(indexFunctional.address, _dataInsuranceStore);
};