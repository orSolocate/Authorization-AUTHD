import { network } from "hardhat";
import { getAddress, isAddress, type Address } from "viem";

const { viem, networkName } = await network.connect();

async function main() {
  if (networkName !== "sepolia") {
    throw new Error(`This script is Sepolia-only. Current network: ${networkName}`);
  }

  const rawServerAddress = "0xfeb91ced20b008f6f5bebc9189ec7837894584a1";
  if (!rawServerAddress) {
    throw new Error("Missing AUTH_SERVER_ADDRESS in environment");
  }

  // strict: false lets you accept a lowercase/non-checksummed 0x address
  if (!isAddress(rawServerAddress, { strict: false })) {
    throw new Error(`Invalid AUTH_SERVER_ADDRESS: ${rawServerAddress}`);
  }

  const serverAddress: Address = getAddress(rawServerAddress);

  const publicClient = await viem.getPublicClient();
  const [walletClient] = await viem.getWalletClients();

  console.log(`Deploying CustomClient to ${networkName}...`);
  console.log(`Deployer: ${walletClient.account.address}`);
  console.log(`Using ERC20Authorized server: ${serverAddress}`);

  const customClient = await viem.deployContract("CustomClient", [serverAddress]);

  console.log("CustomClient deployed to:", customClient.address);

  const blockNumber = await publicClient.getBlockNumber();
  console.log("Current block:", blockNumber.toString());
  console.log("Deployment successful.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/CustomClient_deploy.ts --build-profile production --network sepolia