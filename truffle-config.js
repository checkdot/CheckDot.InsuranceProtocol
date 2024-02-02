const HDWalletProvider = require('@truffle/hdwallet-provider');
var secret = require("./secret");

module.exports = {
  plugins: ['solidity-coverage', 'truffle-plugin-verify'],
  api_keys: {
    bscscan: secret.API_KEY,
    etherscan: secret.ETHER_SCAN_API_KEY
  },
  networks: {
    development: {
      // truffle deploy --network development
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      // replace by local ganache account
      from: "0x7f87C43136F7A4c78788bEb8e39EE400328f184a"
    },
    testnet: { // truffle deploy --network testnet
      provider: () => new HDWalletProvider(secret.MMENOMIC, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    bsc: { // truffle deploy --network bsc
      provider: () => new HDWalletProvider(secret.MMENOMIC, `https://bsc-dataseed4.binance.org`),
      network_id: 56,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      gas: 2000000, // limit
      gasPrice: 5000000000 // Specified in Wei (20Wei)
    },
    eth: {
      // https://infura.io/dashboard/ethereum
      // truffle deploy --network eth
      provider: () => new HDWalletProvider(secret.MMENOMIC, `https://mainnet.infura.io/v3/${secret.INFURA_API_KEY}`),
      network_id: 1,      // Mainnet id
      gas: 5500000,
    }
  },
  compilers: {
    solc: {
      version: "0.8.9",
      settings: {
        optimizer: {
          enabled: true,
          runs: 1
        }
      }
    }
  }
};
