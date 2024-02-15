const hre = require("hardhat");
const { default: Web3 } = require("web3");

async function main() {

  const insuranceProtocolProductProxy = (await hre.ethers.getContractFactory("CheckDotInsuranceProducts")).attach("0xd0331B52C40b8853654483a359ba4E28f9a88c71");

  const test = new Web3();

  const _id = 29;
  const _minCoverInDays = "30";
  const _maxCoverInDays = "365";
  const _basePremiumInPercent = test.utils.toWei(`0.5`, 'ether').toString();
  const _riskRatio = test.utils.toWei(`2.9`, 'ether').toString();
  const _uri = "bafyreifbrkkzjfsbhvx37jc7faqriezkptyapa5szkpinpvpfruvk64ndq/metadata.json";
  const _name = "LUSD Protocol";
  const _riskType = "Oracle Malfunction Risk";

  const _data = test.eth.abi.encodeParameters(['string', 'string', 'string', 'uint256', 'uint256', 'uint256', 'uint256'], [
      _name,
      _riskType,
      _uri,
      _riskRatio,
      _basePremiumInPercent,
      _minCoverInDays,
      _maxCoverInDays
  ]);

  const result = await insuranceProtocolProductProxy.createProduct(_id, _data);

  // const result = await insuranceProtocolCoversProxy.getCover(13);

  console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});