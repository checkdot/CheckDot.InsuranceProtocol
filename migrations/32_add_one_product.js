const CheckDotInsuranceCovers = artifacts.require('CheckDotInsuranceCovers');
const CheckDotInsuranceProducts = artifacts.require('CheckDotInsuranceProducts');

const UpgradableCheckDotInsuranceProducts = artifacts.require('UpgradableCheckDotInsuranceProducts');
const UpgradableCheckDotInsuranceCovers = artifacts.require('UpgradableCheckDotInsuranceCovers');
const UpgradableCheckDotInsuranceCalculator = artifacts.require('UpgradableCheckDotInsuranceCalculator');


module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotInsuranceProducts.deployed();
    const insuranceProducts = await CheckDotInsuranceProducts.at(proxy.address);
    console.log("Proxy", proxy.address);


    // const currentBlockTimeStamp = ((await web3.eth.getBlock("latest")).timestamp) + 1000;
    //function createProduct(uint256 _utcProductStartDate, uint256 _utcProductEndDate, uint256 _minCoverInDays, uint256 _maxCoverInDays, uint256 _basePremiumInPercentPerDay, string calldata _uri, string calldata _title, address[] calldata _coverCurrencies) external;
    
    //////////////////////////
    // AAVE V3
    const _id = 0;
    const _minCoverInDays = "30";
    const _maxCoverInDays = "365";
    const _basePremiumInPercent = web3.utils.toWei(`2.88`, 'ether');
    const _riskRatio = web3.utils.toWei(`2.5`, 'ether');
    const _uri = "bafyreia3vdv3xslgooyxtzeuxfqto4ku2ztcel6rkqizwh5ln4qwzypl4a/metadata.json";
    const _name = "AAVE V3";
    const _riskType = "Smart Contract Vulnerability";
    //////////////////////////
    // PancakeSwap
    // const _id = 1;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.15`, 'ether');
    // const _riskRatio = web3.utils.toWei(`2.4`, 'ether');
    // const _uri = "bafyreig5m4m2ymhqtgixu33qhu2wpqrnnz3gvgqsu4txl3n5hhwemulbh4/metadata.json";
    // const _name = "PancakeSwap";
    // const _riskType = "Smart Contract Vulnerability";
    //////////////////////////
    // PancakeSwap
    // const DAY = 86400;
    // const YEAR = (DAY * 365);
    // const _utcProductStartDate = `${currentBlockTimeStamp.toFixed(0)}`;
    // const _utcProductEndDate = `${(currentBlockTimeStamp + (YEAR * 2)).toFixed(0)}`;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.15`, 'ether');
    // const _riskRatio = web3.utils.toWei(`2.4`, 'ether');
    // const _uri = "bafyreig5m4m2ymhqtgixu33qhu2wpqrnnz3gvgqsu4txl3n5hhwemulbh4/metadata.json";
    // const _name = "PancakeSwap";
    // const _riskType = "Smart Contract Vulnerability";


    ///////////////////////

    const _data = web3.eth.abi.encodeParameters(_id, ['string', 'string', 'string', 'uint256', 'uint256', 'uint256', 'uint256'], [
        _name,
        _riskType,
        _uri,
        _riskRatio,
        _basePremiumInPercent,
        _minCoverInDays,
        _maxCoverInDays
    ]);

    await insuranceProducts.createProduct(_data);
};