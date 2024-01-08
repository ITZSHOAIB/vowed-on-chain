import hre, { artifacts } from "hardhat";
import path from "path";
import fs from "fs";

async function main() {
  const deployedContract = await hre.viem.deployContract("VowedOnChain");
  console.log(`Contract has been deployed to ${deployedContract.address}`);
  saveArtifacts(deployedContract);
}

function saveArtifacts(contract: any) {
  const contractsDir = path.join(
    __dirname,
    "..",
    "..",
    "vowed-on-chain-ui",
    "artifacts"
  );

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    path.join(contractsDir, "contract-address.json"),
    JSON.stringify({ VowedOnChainAddress: contract.address }, undefined, 2)
  );

  const VowedOnChainArtifacts = artifacts.readArtifactSync("VowedOnChain");

  fs.writeFileSync(
    path.join(contractsDir, "VowedOnChain.json"),
    JSON.stringify(VowedOnChainArtifacts, null, 2)
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run --network localhost scripts/deploy.ts
