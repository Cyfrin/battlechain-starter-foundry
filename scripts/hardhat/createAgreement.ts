/// @notice Step 2 (Protocol): Create a Safe Harbor agreement and adopt it.
///
/// Prerequisites:
///   PRIVATE_KEY    — stored in Hardhat keystore (run: just hh-import-key)
///   VAULT_ADDRESS  — set in .env after running: just hh-setup
///
/// Usage:
///   npm run create-agreement
///   (or: npx hardhat run scripts/hardhat/createAgreement.ts)

import { ethers } from "ethers";
import { network } from "hardhat";
import {
  BC,
  IAgreementABI,
  IAgreementFactoryABI,
  IBCSafeHarborRegistryABI,
} from "./abis.js";

const COMMITMENT_WINDOW_DAYS = 30;

// ChildContractScope.All = 2  (from AgreementTypes.sol)
const CHILD_CONTRACT_SCOPE_ALL = 2;
// IdentityRequirements.Anonymous = 0
const IDENTITY_ANONYMOUS = 0;

const vaultAddress = process.env["VAULT_ADDRESS"];
if (!vaultAddress) throw new Error("VAULT_ADDRESS not set in .env");

const { ethers: hethers } = await network.connect({
  network: "battlechain",
  chainType: "l1",
});

const [signer] = await hethers.getSigners();

const factory = new ethers.Contract(BC.AGREEMENT_FACTORY, IAgreementFactoryABI, signer);
const registry = new ethers.Contract(BC.REGISTRY, IBCSafeHarborRegistryABI, signer);

// 1. Build AgreementDetails
const details = {
  protocolName: "BattleChain Starter Demo",
  contactDetails: [{ name: "Security Team", contact: "security@example.com" }],
  chains: [
    {
      assetRecoveryAddress: signer.address,
      accounts: [
        {
          accountAddress: vaultAddress,
          childContractScope: CHILD_CONTRACT_SCOPE_ALL,
        },
      ],
      caip2ChainId: BC.CAIP2_CHAIN_ID,
    },
  ],
  bountyTerms: {
    bountyPercentage: 10n,
    bountyCapUsd: 5_000_000n,
    retainable: true,
    identity: IDENTITY_ANONYMOUS,
    diligenceRequirements: "",
    aggregateBountyCapUsd: 0n,
  },
  agreementURI: BC.SAFE_HARBOR_URI,
};

const salt = ethers.keccak256(
  ethers.concat([
    ethers.toUtf8Bytes("agreement-v1"),
    ethers.getBytes(signer.address),
  ])
);

// 2. Create agreement — get address via staticCall, then broadcast
const agreementAddress = await factory.create.staticCall(details, signer.address, salt);
const tx1 = await factory.create(details, signer.address, salt);
await tx1.wait();
console.log("Agreement created:", agreementAddress);

// 3. Extend commitment window
const agreement = new ethers.Contract(agreementAddress, IAgreementABI, signer);
const block = await hethers.provider.getBlock("latest");
const newCantChangeUntil =
  BigInt(block!.timestamp) + BigInt(COMMITMENT_WINDOW_DAYS * 24 * 60 * 60);
const tx2 = await agreement.extendCommitmentWindow(newCantChangeUntil);
await tx2.wait();
console.log("Commitment window extended", COMMITMENT_WINDOW_DAYS, "days");

// 4. Adopt the agreement
const tx3 = await registry.adoptSafeHarbor(agreementAddress);
await tx3.wait();
console.log("Safe Harbor adopted");

console.log("\n--- Add to your .env ---");
console.log(`AGREEMENT_ADDRESS=${agreementAddress}`);
