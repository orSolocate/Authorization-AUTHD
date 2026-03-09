import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import { configVariable, defineConfig } from "hardhat/config";
import hardhatIgnoreWarnings from "hardhat-ignore-warnings";

export default defineConfig({
  solidity: {
    version: "0.8.28",
  },
  networks: {
    sepolia: {
      type: "http",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
  },
  verify: {
    etherscan: {
      apiKey: configVariable("ETHERSCAN_API_KEY"),
    },
  },
  plugins: [hardhatToolboxViemPlugin, hardhatIgnoreWarnings],
  warnings: {
    'test/**/*': {
      'code-size': 'off',
      default: 'warn',
    },
    'contracts/**/*': {
      default: 'warn',
    },
  }
});
