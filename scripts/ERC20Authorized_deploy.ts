import { network } from "hardhat";

const { viem, networkName } = await network.connect();

async function main() {
  if (networkName !== "sepolia") {
    throw new Error(`This script is Sepolia-only. Current network: ${networkName}`);
  }

  const publicClient = await viem.getPublicClient();
  const [walletClient] = await viem.getWalletClients();

  console.log(`Deploying ERC20Authorized to ${networkName}...`);
  console.log(`Deployer: ${walletClient.account.address}`);

  const erc20Authorized = await viem.deployContract("ERC20Authorized");

  console.log("ERC20Authorized deployed to:", erc20Authorized.address);

  const blockNumber = await publicClient.getBlockNumber();
  console.log("Current block:", blockNumber.toString());

  console.log("Deployment successful.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});