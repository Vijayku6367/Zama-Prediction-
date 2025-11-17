import { ethers } from "hardhat";

async function main() {
  const factory = await ethers.getContractFactory("PredictionBeliefMarket");
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  console.log("PredictionBeliefMarket deployed at:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
