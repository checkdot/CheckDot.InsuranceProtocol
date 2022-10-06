const CheckDotERC721InsuranceToken = artifacts.require('CheckDotERC721InsuranceToken');

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

    const proxy = await UpgradableCheckDotERC721InsuranceToken.deployed();
    const indexFunctional = await CheckDotERC721InsuranceToken.deployed();

    console.log("Proxy", proxy.address);
    console.log("CheckDotERC721InsuranceToken", indexFunctional.address);

    const _dataInsuranceStore = web3.eth.abi.encodeParameters(['address', 'address', 'address'], [
        insuranceProtocolProxy.address,
        insurancePoolFactoryProxy.address,
        insuranceRiskDataCalculatorProxy.address
    ]);

    await proxy.upgrade(indexFunctional.address, _dataInsuranceStore);
};