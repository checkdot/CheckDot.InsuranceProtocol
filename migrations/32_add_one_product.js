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
    // const _id = 0;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`2.88`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.5`, 'ether').toString();
    // const _uri = "bafyreia3vdv3xslgooyxtzeuxfqto4ku2ztcel6rkqizwh5ln4qwzypl4a/metadata.json";
    // const _name = "AAVE V3";
    // const _riskType = "Smart Contract Vulnerability";
    //////////////////////////
    // PancakeSwap
    // const _id = 1;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.15`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.4`, 'ether').toString();
    // const _uri = "bafyreig5m4m2ymhqtgixu33qhu2wpqrnnz3gvgqsu4txl3n5hhwemulbh4/metadata.json";
    // const _name = "PancakeSwap";
    // const _riskType = "Smart Contract Vulnerability";
    //////////////////////////
    // Lido
    // const _id = 2;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.6`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.0`, 'ether').toString();
    // const _uri = "bafyreig3fzlqj262jpdwkb3avnkt7mp6bok4m5zs3nrznxtc4qvvsd3ihq/metadata.json";
    // const _name = "Lido";
    // const _riskType = "Smart Contract Vulnerability";
    //////////////////////////
    // Binance Exchange
    // const _id = 3;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.75`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.0`, 'ether').toString();
    // const _uri = "bafyreiasllvxm4vva7wffeqv4duhskiujfzannlg3gq5mf7wdta4nhhppu/metadata.json";
    // const _name = "Binance Exchange";
    // const _riskType = "Platform Hacks";
    ///////////////////////
    // // Crypto.com Exchange
    // const _id = 4;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.6`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.0`, 'ether').toString();
    // const _uri = "bafyreih3twmaulxyz2h2563iz7l7pmjppuwvqv7tmwvpguzcyahjkpd4zm/metadata.json";
    // const _name = "Crypto.com Exchange";
    // const _riskType = "Platform Hacks";
    // ///////////////////////
    // USDT Peg
    // const _id = 5;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`2.7`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`1.9`, 'ether').toString();
    // const _uri = "bafyreie2eynrlasuz2bh7mtyq5girhdaulmoqzkab4dpoakiierubgrrye/metadata.json";
    // const _name = "USDT Peg";
    // const _riskType = "Stablecoin De-Peg Risk";
    ///////////////////////
    // USDC Peg
    // const _id = 6;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`2.7`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`1.9`, 'ether').toString();
    // const _uri = "bafyreigqdps6onvtboty3ctegtvk7tns42qqyl2rpkdz6djim3c2tqpk54/metadata.json";
    // const _name = "USDC Peg";
    // const _riskType = "Stablecoin De-Peg Risk";
    ///////////////////////
    // BUSD Peg
    const _id = 7;
    const _minCoverInDays = "30";
    const _maxCoverInDays = "365";
    const _basePremiumInPercent = web3.utils.toWei(`2.7`, 'ether').toString();
    const _riskRatio = web3.utils.toWei(`1.9`, 'ether').toString();
    const _uri = "bafyreidiea4ro6slkjgxzxikntid2wof5l3zy56rgkhjujzq53hw7jvauu/metadata.json";
    const _name = "BUSD Peg";
    const _riskType = "Stablecoin De-Peg Risk";
    ///////////////////////

    const _data = web3.eth.abi.encodeParameters(['string', 'string', 'string', 'uint256', 'uint256', 'uint256', 'uint256'], [
        _name,
        _riskType,
        _uri,
        _riskRatio,
        _basePremiumInPercent,
        _minCoverInDays,
        _maxCoverInDays
    ]);

    await insuranceProducts.createProduct(_id, _data);
};