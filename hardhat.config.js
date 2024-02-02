/** @type import('hardhat/config').HardhatUserConfig */
var secret = require("./secret");
require("@nomiclabs/hardhat-ethers");
require('@nomiclabs/hardhat-etherscan');
require('hardhat-deploy');

module.exports = {
  etherscan: {
    apiKey: {
      bsc: secret.API_KEY
    }
  },
  networks: {
    bsc: {
        // truffle deploy --network avax
        url: `https://bsc-dataseed4.binance.org`,
        accounts: [secret.MMENOMIC],
        verify: {
          etherscan: {
            apiUrl: 'https://api.bscscan.com'
          }
        }
    }
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100
      }
    }
  }
};