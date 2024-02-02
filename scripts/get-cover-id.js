const hre = require("hardhat");
const { default: Web3 } = require("web3");

async function main() {

  const insuranceProtocolCoversProxy = (await hre.ethers.getContractFactory("CheckDotInsuranceCovers")).attach("0x9c84a04E232fF0AACa867F3d6B6e0Fca96f29ee7");

  const result = await insuranceProtocolCoversProxy.getCover(13);

  console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});