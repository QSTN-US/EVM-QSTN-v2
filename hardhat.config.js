require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-gas-reporter");
require("hardhat-tracer");
require("dotenv").config({ path: __dirname + "/.env" });

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 800,
          },
        },
      },
    ],
  },
  defaultNetwork: "hardhat",
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    customChains: [
      {
        network: "polygonAmoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com",
        },
      },
      {
        network: "kakarot_sepolia",
        chainId: 1802203764,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/testnet/evm/1802203764_2/etherscan",
          browserURL: "https://sepolia.kakarotscan.org",
        },
      },
    ],
  },

  networks: {
    hardhat: {},
    amoy: {
      url: process.env.AMM_FORK_URL,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
      chainId: 80002,
    },
    rootTest: {
      url: "https://public-node.testnet.rsk.co",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
      chainId: 31,
    },
  },

  mocha: {
    timeout: 1000000000000000,
  },

  gasReporter: {
    currency: "USD",
    L1: "ethereum",
    coinmarketcap: "abc123...",
    enabled: false,
  },
};
