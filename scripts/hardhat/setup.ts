/// @notice Step 1 (Protocol): Deploy MockToken + VulnerableVault, seed the vault.
///
/// Prerequisites:
///   PRIVATE_KEY — stored in Hardhat keystore (run: just hh-import-key)
///
/// Usage:
///   npm run setup
///   (or: npx hardhat run scripts/hardhat/setup.ts)

import { ethers } from "ethers";
import { network } from "hardhat";
import { BC, IBCDeployerABI } from "./abis.js";

const SEED_AMOUNT = ethers.parseEther("1000");

const { ethers: hethers } = await network.connect({
  network: "battlechain",
  chainType: "l1",
});

const [signer] = await hethers.getSigners();
const deployer = new ethers.Contract(BC.DEPLOYER, IBCDeployerABI, signer);

// 1. Deploy MockToken — get address via staticCall, then broadcast
const MockToken = await hethers.getContractFactory("MockToken");
const tokenInitCode = MockToken.bytecode;

const tokenAddress = await deployer.deployCreate.staticCall(tokenInitCode);
const tx1 = await deployer.deployCreate(tokenInitCode);
await tx1.wait();
console.log("MockToken deployed:", tokenAddress);

// 2. Deploy VulnerableVault with CREATE2 for a deterministic address
const VulnerableVault = await hethers.getContractFactory("VulnerableVault");
const vaultInitCode = ethers.concat([
  VulnerableVault.bytecode,
  ethers.AbiCoder.defaultAbiCoder().encode(["address"], [tokenAddress]),
]);

const salt = ethers.keccak256(
  ethers.concat([
    ethers.toUtf8Bytes("vulnerable-vault-v1"),
    ethers.getBytes(signer.address),
  ])
);

const vaultAddress = await deployer.deployCreate2.staticCall(salt, vaultInitCode);
const tx2 = await deployer.deployCreate2(salt, vaultInitCode);
await tx2.wait();
console.log("VulnerableVault deployed:", vaultAddress);

// 3. Seed the vault with tokens to represent protocol liquidity
const token = MockToken.attach(tokenAddress).connect(signer) as ethers.Contract;
const vault = VulnerableVault.attach(vaultAddress).connect(signer) as ethers.Contract;

const tx3 = await token.mint(signer.address, SEED_AMOUNT);
await tx3.wait();

const tx4 = await token.approve(vaultAddress, SEED_AMOUNT);
await tx4.wait();

const tx5 = await vault.deposit(SEED_AMOUNT);
await tx5.wait();
console.log("Vault seeded with", ethers.formatEther(SEED_AMOUNT), "tokens");

console.log("\n--- Add to your .env ---");
console.log(`TOKEN_ADDRESS=${tokenAddress}`);
console.log(`VAULT_ADDRESS=${vaultAddress}`);
