const CheckDotPoolFactory = artifacts.require('CheckDotPoolFactory');
const CheckDotInsuranceProtocol = artifacts.require('CheckDotInsuranceProtocol');

const UpgradableCheckDotInsuranceProtocol = artifacts.require('UpgradableCheckDotInsuranceProtocol');
const UpgradableCheckDotPoolFactory = artifacts.require('UpgradableCheckDotPoolFactory');
const UpgradableCheckDotERC721InsuranceToken = artifacts.require('UpgradableCheckDotERC721InsuranceToken');
const UpgradableCheckDotInsuranceRiskDataCalculator = artifacts.require('UpgradableCheckDotInsuranceRiskDataCalculator');


module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceProtocol.deployed();
    const protocol = await CheckDotInsuranceProtocol.at(proxy.address);
    console.log("Proxy", proxy.address);


    // const _tokenAddress = "0x55d398326f99059ff775485246999027b3197955";// USDT
    // const _minCoverAmount = web3.utils.toWei(`100`, 'ether');
    // const _maxCoverAmount = web3.utils.toWei(`50000`, 'ether');

    const _tokenAddress = "0xe9e7cea3dedca5984780bafc599bd69add087d56";// BUSD
    const _minCoverAmount = web3.utils.toWei(`100`, 'ether');
    const _maxCoverAmount = web3.utils.toWei(`50000`, 'ether');

    const _data = web3.eth.abi.encodeParameters(['address', 'uint256', 'uint256'], [
        _tokenAddress,
        _minCoverAmount,
        _maxCoverAmount
    ]);

    await protocol.addCoverCurrency(_data);
};