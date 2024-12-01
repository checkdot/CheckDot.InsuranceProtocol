const hre = require("hardhat");
const { default: Web3 } = require("web3");

async function main() {

  const insuranceProtocolProxy = (await hre.ethers.getContractFactory("UpgradableCheckDotInsuranceCalculator")).attach("0x12DE80A36BadfC186253304C3d3dD79b160E0079");

  const newAddress = '0x1a56cFbE390a347C13C0277138FcC17D10b59053';
  const test = new Web3();
  const _dataInit = test.eth.abi.encodeParameters(['address', 'address', 'address', 'address', 'address', 'address'], [
    "0xd0331B52C40b8853654483a359ba4E28f9a88c71", // Products Address
    "0x9c84a04e232ff0aaca867f3d6b6e0fca96f29ee7", // Covers Address
    "0x0cbd6fadcf8096cc9a43d90b45f65826102e3ece", // CDTGouvernanceTokenAddress
    "0x10ED43C718714eb63d5aA57B78B54704E256024E", // Pcswp v2
    "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", // BUSD
    "0x55d398326f99059fF775485246999027B3197955" // USDT
  ]);

  const result = await insuranceProtocolProxy.upgrade(newAddress, _dataInit);

  console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});