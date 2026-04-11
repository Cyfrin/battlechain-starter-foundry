// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {BCSafeHarbor} from "battlechain-lib/BCSafeHarbor.sol";
import {
    AgreementDetails,
    Contact,
    BountyTerms,
    IdentityRequirements
} from "battlechain-lib/types/AgreementTypes.sol";

/// @notice Step 2 (Protocol): Create a Safe Harbor agreement and adopt it.
///
/// Prerequisites — set in .env:
///   SENDER_ADDRESS, VAULT_ADDRESS
///
/// Usage:
///   just create-agreement
///
/// After running, copy AGREEMENT_ADDRESS into your .env file.
contract CreateAgreement is BCSafeHarbor {
    uint256 constant COMMITMENT_WINDOW = 30;

    function run() external {
        address vault = vm.envAddress("VAULT_ADDRESS");

        vm.startBroadcast();

        // 1. Contact details
        Contact[] memory contacts = new Contact[](1);
        contacts[0] = Contact({name: "Security Team", contact: "security@example.com"});

        // 2. Scope: put VulnerableVault in scope on the current chain
        address[] memory contracts_ = new address[](1);
        contracts_[0] = vault;

        // 3. Bounty terms
        BountyTerms memory bountyTerms = BountyTerms({
            bountyPercentage: 10,
            bountyCapUsd: 5_000_000,
            retainable: true,
            identity: IdentityRequirements.Anonymous,
            diligenceRequirements: "",
            aggregateBountyCapUsd: 0
        });

        // 4. Build agreement details (auto-detects chain scope and URI)
        AgreementDetails memory details = defaultAgreementDetails(
            "BattleChain Starter Demo", contacts, contracts_, msg.sender
        );
        details.bountyTerms = bountyTerms;

        // 5. Create, set commitment window, and adopt
        address agreement = createAgreement(details, msg.sender, keccak256(abi.encodePacked("agreement-v1", msg.sender, vault)));
        setCommitmentWindow(agreement, COMMITMENT_WINDOW);
        adoptAgreement(agreement);

        vm.stopBroadcast();

        console.log("Agreement created:", agreement);
        console.log("Commitment window extended", COMMITMENT_WINDOW, "days");
        console.log("Safe Harbor adopted");
        console.log("\n--- Add to your .env ---");
        console.log("AGREEMENT_ADDRESS=%s", agreement);
    }
}
