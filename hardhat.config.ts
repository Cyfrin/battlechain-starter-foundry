import hardhatEthers from "@nomicfoundation/hardhat-ethers";
import hardhatKeystore from "@nomicfoundation/hardhat-keystore";
import hardhatVerify from "@nomicfoundation/hardhat-verify";
import { configVariable, defineConfig } from "hardhat/config";

export default defineConfig({
  plugins: [hardhatEthers, hardhatKeystore, hardhatVerify],
  solidity: {
    profiles: {
      default: {
        version: "0.8.24",
      },
    },
  },
  paths: {
    // Only compile src/ — script/ and test/ use forge-std which Hardhat cannot resolve
    sources: "./src",
    // Hardhat tests go in test/hardhat/ to avoid Foundry's test/ directory
    tests: "./test/hardhat",
    artifacts: "./artifacts",
    cache: "./cache/hardhat",
  },
  networks: {
    battlechain: {
      type: "http",
      chainType: "l1",
      url: "https://testnet.battlechain.com:3051",
      accounts: [configVariable("PRIVATE_KEY")],
    },
  },
  etherscan: {
    apiKey: {
      battlechain: "not-required",
    },
    customChains: [
      {
        network: "battlechain",
        chainId: 627,
        urls: {
          apiURL: "https://block-explorer-api.testnet.battlechain.com/api",
          browserURL: "https://explorer.testnet.battlechain.com",
        },
      },
    ],
  },
});
