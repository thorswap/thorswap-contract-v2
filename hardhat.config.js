require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    mainnet: {
      url: "https://mainnet.infura.io/v3/f9dfccab907d4cc891817733689eaff4",
      accounts: [process.env.THORSWAP_WALLET_PRIVATE_KEY],
    },
    ropsten: {
      url: "https://ropsten.infura.io/v3/f9dfccab907d4cc891817733689eaff4",
      accounts: [process.env.THORSWAP_WALLET_PRIVATE_KEY],
    },
  },
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000,
      },
    },
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./out",
  },
  mocha: {
    timeout: 40000,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
