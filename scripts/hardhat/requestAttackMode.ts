/// @notice Step 3 (Protocol): Submit the attack mode request for DAO review.
///
/// Prerequisites:
///   PRIVATE_KEY        — stored in Hardhat keystore (run: just hh-import-key)
///   AGREEMENT_ADDRESS  — set in .env after running: just hh-create-agreement
///
/// Usage:
///   npm run request-attack-mode
///   (or: npx hardhat run scripts/hardhat/requestAttackMode.ts)
///
/// After running, wait for DAO approval. Check state with cast:
///   cast call $ATTACK_REGISTRY "getAgreementState(address)(uint8)" $AGREEMENT_ADDRESS \
///     --rpc-url https://testnet.battlechain.com:3051
///   # 2 = ATTACK_REQUESTED, 3 = UNDER_ATTACK (approved)

import { ethers } from "ethers";
import { network } from "hardhat";
import { BC, IAttackRegistryABI } from "./abis.js";

const agreementAddress = process.env["AGREEMENT_ADDRESS"];
if (!agreementAddress) throw new Error("AGREEMENT_ADDRESS not set in .env");

const { ethers: hethers } = await network.connect({
  network: "battlechain",
  chainType: "l1",
});

const [signer] = await hethers.getSigners();
const attackRegistry = new ethers.Contract(BC.ATTACK_REGISTRY, IAttackRegistryABI, signer);

const tx = await attackRegistry.requestUnderAttack(agreementAddress);
await tx.wait();

console.log("Attack mode requested for agreement:", agreementAddress);
console.log("State is now ATTACK_REQUESTED (2) - awaiting DAO approval.");
console.log("Once approved, state moves to UNDER_ATTACK (3).");
