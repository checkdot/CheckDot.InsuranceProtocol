const hre = require("hardhat");
const { default: Web3 } = require("web3");

async function main() {

  const insuranceProtocolCoversProxy = (await hre.ethers.getContractFactory("UpgradableCheckDotInsuranceProducts")).attach("0xd0331B52C40b8853654483a359ba4E28f9a88c71");

  // old implementation 0xbf727DC9560Ae5a1Bde687C3D5672ccB2904A67C (Avec la faille de teamApproval)
  const newAddress = '0x5967aA4b8EF331ea37bF16c832563a7AB2315216';
  const test = new Web3();
  const _dataInit = test.eth.abi.encodeParameters(['address', 'address'], [
      "0x9c84a04e232ff0aaca867f3d6b6e0fca96f29ee7", // Covers Address
      "0x12DE80A36BadfC186253304C3d3dD79b160E0079" // calculatorAddress
  ]);

  const result = await insuranceProtocolCoversProxy.upgrade(newAddress, _dataInit);

  console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});