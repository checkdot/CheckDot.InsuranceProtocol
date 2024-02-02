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
    // const _basePremiumInPercent = web3.utils.toWei(`1.5`, 'ether').toString();
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
    // const _basePremiumInPercent = web3.utils.toWei(`1.1`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`1.9`, 'ether').toString();
    // const _uri = "bafyreie2eynrlasuz2bh7mtyq5girhdaulmoqzkab4dpoakiierubgrrye/metadata.json";
    // const _name = "USDT Peg";
    // const _riskType = "Stablecoin De-Peg Risk";
    ///////////////////////
    // USDC Peg
    // const _id = 6;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.1`, 'ether').toString();
    // const _uri = "bafyreigqdps6onvtboty3ctegtvk7tns42qqyl2rpkdz6djim3c2tqpk54/metadata.json";
    // const _name = "USDC Peg";
    // const _riskType = "Stablecoin De-Peg Risk";
    ///////////////////////
    // BUSD Peg
    // const _id = 7;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`2.2`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`1.9`, 'ether').toString();
    // const _uri = "bafyreidiea4ro6slkjgxzxikntid2wof5l3zy56rgkhjujzq53hw7jvauu/metadata.json";
    // const _name = "BUSD Peg";
    // const _riskType = "Stablecoin De-Peg Risk";
    ///////////////////////
    // MIM Peg
    // const _id = 8;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.5`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.5`, 'ether').toString();
    // const _uri = "bafyreib5izkfwi5ivtvoydjvmkpt5mbeeo74gvtgd3rkn23i5tn35sw56m/metadata.json";
    // const _name = "MIM Peg";
    // const _riskType = "Stablecoin De-Peg Risk";
    ///////////////////////
    // Uniswap Protocol
    // const _id = 9;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.7`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.5`, 'ether').toString();
    // const _uri = "bafyreih4je3iexy3jm25qfvuzalbjrvulaogbfb5t5czqgvhtc22cur6lu/metadata.json";
    // const _name = "Uniswap Protocol";
    // const _riskType = "Smart Contract Vulnerability";
    ///////////////////////
    // Benqi
    // const _id = 10;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.1`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`1.4`, 'ether').toString();
    // const _uri = "bafyreiatql5zjy3s2kcci75momirgfa2xia2dyvk2d4tbya2bxfj7xlhce/metadata.json";
    // const _name = "Benqi";
    // const _riskType = "Smart Contract Vulnerability";
    ///////////////////////
    // Curve (All Pools)
    // const _id = 11;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.1`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`1.8`, 'ether').toString();
    // const _uri = "bafyreifmffqxt2bntl5xxnf5x4kvux6xzejyaaf7dilg4cghs67dvf7dpy/metadata.json";
    // const _name = "Curve (All Pools)";
    // const _riskType = "Smart Contract Vulnerability";
    ///////////////////////
    // Raydium
    // const _id = 12;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "180";
    // const _basePremiumInPercent = web3.utils.toWei(`4.0`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.5`, 'ether').toString();
    // const _uri = "bafyreiecbsora3yzzg6yddlqvivwff6wt7dbj3tatire2kej6qe3cbmbdu/metadata.json";
    // const _name = "Raydium";
    // const _riskType = "Smart Contract Vulnerability";
    ///////////////////////
    // Ftx
    // const _id = 13;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "180";
    // const _basePremiumInPercent = web3.utils.toWei(`12.2`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`0.8`, 'ether').toString();
    // const _uri = "bafyreibuemecy5bspbzrjxx7hoduyszr37ranrpfznrfcdct5rcybnmh6e/metadata.json";
    // const _name = "Ftx Exchange";
    // const _riskType = "Custodian Risk";
    ///////////////////////
    // CoinBase
    // const _id = 14;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`3.6`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.1`, 'ether').toString();
    // const _uri = "bafyreidbsvku373theos4egtxwnvatqzoquioezve6r6ihsthigqx373eu/metadata.json";
    // const _name = "CoinBase Exchange";
    // const _riskType = "Custodian Risk";
    ///////////////////////
    // Kraken
    // const _id = 15;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`0.5`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.9`, 'ether').toString();
    // const _uri = "bafyreifuiai6fk7rppgyvmksb27wqn775fqbpa4esgxooy7ubhxykzidue/metadata.json";
    // const _name = "Kraken Exchange";
    // const _riskType = "Custodian Risk";
    ///////////////////////
    // // Gate.io
    // const _id = 16;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.0`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.7`, 'ether').toString();
    // const _uri = "bafyreig33ey4h7bpd55hw5qmxw6db23jsjdje3ugr2ztljdwtnwvxlp2m4/metadata.json";
    // const _name = "Gate.io Exchange";
    // const _riskType = "Custodian Risk";
    ///////////////////////
    // // BitMEX
    // const _id = 17;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.1`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.6`, 'ether').toString();
    // const _uri = "bafyreibuxopkwq276tsbg77hr3n47ug3dobwunbk6ezsojzskwzkxuf5pq/metadata.json";
    // const _name = "BitMEX Exchange";
    // const _riskType = "Custodian Risk";
    ///////////////////////
    // // KuCoin
    // const _id = 18;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.7`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.1`, 'ether').toString();
    // const _uri = "bafyreickg7orzzb7uqbwcrzoofmkrk4reqx3f6bofcqu6ith3djmqahi7u/metadata.json";
    // const _name = "KuCoin Exchange";
    // const _riskType = "Custodian Risk";
    ///////////////////////
    // // Celer Bridge
    // const _id = 19;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.2`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.7`, 'ether').toString();
    // const _uri = "bafyreibgczvkxtfkzqjoqs4k2hgrsiszxepwwejtdliotkmtjgxy5hezmy/metadata.json";
    // const _name = "Celer Bridge";
    // const _riskType = "Hacks Risk";
    ///////////////////////
    // O3Swap
    // const _id = 20;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.5`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.2`, 'ether').toString();
    // const _uri = "bafyreiasdfl4cxofbe6pjxwi5b5zt4zybxu6zs6iis5sqmbj72ltzfryvu/metadata.json";
    // const _name = "O3Swap";
    // const _riskType = "Hacks Risk";
    ///////////////////////
    // Multichain.xyz
    // const _id = 21;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.3`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.3`, 'ether').toString();
    // const _uri = "bafyreihlngz6ugz5en6yue5rhqfagt2oziebqc24lu23uhk4yt64srhpgi/metadata.json";
    // const _name = "Multichain.xyz";
    // const _riskType = "Hacks Risk";
    ///////////////////////
    // Changelly.com
    // const _id = 22;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.3`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.2`, 'ether').toString();
    // const _uri = "bafyreianf27urhnpxhtjbbblv73jzx34namsdnw2dwmjg2mefnbuvzi5yq/metadata.json";
    // const _name = "Changelly.com";
    // const _riskType = "Hacks Risk";
    ///////////////////////
    // stUSDT / wstUSDT
    // const _id = 23;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.2`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`0.9`, 'ether').toString();
    // const _uri = "bafyreig2dyurinibofdvxf4rnx2jt2feysyf7edakmwpxbq3jclvggbnmm/metadata.json";
    // const _name = "stUSDT / wstUSDT";
    // const _riskType = "Stablecoin De-Peg Risk";
    ///////////////////////
    // const _id = 24;
    // const _minCoverInDays = "7";
    // const _maxCoverInDays = "30";
    // const _basePremiumInPercent = web3.utils.toWei(`12`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`1.5`, 'ether').toString();
    // const _uri = "bafyreib4mtnriyjin4zx64vfs2q6jlsqsfqtuma6ftlrgnosxskmmffvnu/metadata.json";
    // const _name = "Bitcoin Hard De-peg";
    // const _riskType = "Bitcoin Hard De-Peg Risk";
    ///////////////////////
    // const _id = 25;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.8`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.2`, 'ether').toString();
    // const _uri = "bafyreid6wcsho3at5ypg2a7ojbx73umxtbr2nwk47vmoo5xpq5c5kpt3he/metadata.json";
    // const _name = "Orbiter.finance";
    // const _riskType = "Hacks Risk";
    //////////////////////
    // const _id = 26;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`2.3`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.1`, 'ether').toString();
    // const _uri = "bafyreihfcw6m7d5kcz5gvvrggjeubg7m5d74qc6unf2bfh73obx5it67zq/metadata.json";
    // const _name = "Synapse Protocol";
    // const _riskType = "Hacks Risk";
    // //////////////////////
    // const _id = 27;
    // const _minCoverInDays = "30";
    // const _maxCoverInDays = "365";
    // const _basePremiumInPercent = web3.utils.toWei(`1.8`, 'ether').toString();
    // const _riskRatio = web3.utils.toWei(`2.2`, 'ether').toString();
    // const _uri = "bafyreifyz5yuihkhshgmf2fseqqhzzz6ecsvxelzxqcgwugdk56c4c2swa/metadata.json";
    // const _name = "Stargate.finance";
    // const _riskType = "Hacks Risk";
    //////////////////////
    const _id = 28;
    const _minCoverInDays = "30";
    const _maxCoverInDays = "365";
    const _basePremiumInPercent = web3.utils.toWei(`12`, 'ether').toString();
    const _riskRatio = web3.utils.toWei(`1.5`, 'ether').toString();
    const _uri = "bafyreidkjmcgzwdekz67kzzdwfq5q7xaebopavo6o2j5oifxy5hdn6eone/metadata.json";
    const _name = "Ethereum Hard De-peg";
    const _riskType = "Hard De-Peg Risk";

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