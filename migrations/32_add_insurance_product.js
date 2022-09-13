const UpgradableCheckDotInsuranceStore = artifacts.require('UpgradableCheckDotInsuranceStore');
const CheckDotInsuranceStore = artifacts.require('CheckDotInsuranceStore');
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


    const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 1000;
    //function createProduct(uint256 _utcProductStartDate, uint256 _utcProductEndDate, uint256 _minCoverInDays, uint256 _maxCoverInDays, uint256 _basePremiumInPercentPerDay, string calldata _uri, string calldata _title, address[] calldata _coverCurrencies) external;
    const DAY = 86400;
    const YEAR = (DAY * 365);
    const _utcProductStartDate = `${currentBlockTimeStamp.toFixed(0)}`;
    const _utcProductEndDate = `${(currentBlockTimeStamp + (YEAR * 2)).toFixed(0)}`;
    const _minCoverInDays = "1";
    const _maxCoverInDays = "365";
    const _basePremiumInPercent = web3.utils.toWei(`0.85`, 'ether');
    const _riskRatio = web3.utils.toWei(`2.5`, 'ether');
    const _uri = "bafyreia3vdv3xslgooyxtzeuxfqto4ku2ztcel6rkqizwh5ln4qwzypl4a/metadata.json";
    const _name = "AAVE V3";
    const _riskType = "Smart Contract Vulnerability";

    const _data = web3.eth.abi.encodeParameters(['string', 'string', 'string', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256'], [
        _name,
        _riskType,
        _uri,
        _utcProductStartDate,
        _utcProductEndDate,
        _riskRatio,
        _basePremiumInPercent,
        _minCoverInDays,
        _maxCoverInDays
    ]);

    await protocol.createProduct(_data);
};