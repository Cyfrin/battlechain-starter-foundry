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

/// @notice MCP-only: create the Safe Harbor agreement, set its commitment window, and
/// adopt it — all in one run (three transactions). The MCP signs each via MetaMask, so
/// bundling keeps its `create_agreement` step to a single tool call. The browser/keystore
/// flows split these into separate single-tx steps (cast can't do multi-tx cleanly); the
/// MCP can, so it uses this.
///
/// Prerequisites — set in .env: SENDER_ADDRESS, VAULT_ADDRESS
contract McpCreateAgreement is BCSafeHarbor {
    function run() external {
        address vault = vm.envAddress("VAULT_ADDRESS");

        vm.startBroadcast();

        Contact[] memory contacts = new Contact[](1);
        contacts[0] = Contact({name: "Security Team", contact: "security@example.com"});

        address[] memory contracts_ = new address[](1);
        contracts_[0] = vault;

        AgreementDetails memory details =
            defaultAgreementDetails("BattleChain Starter Demo", contacts, contracts_, msg.sender);
        details.bountyTerms = BountyTerms({
            bountyPercentage: 10,
            bountyCapUsd: 5_000_000,
            retainable: true,
            identity: IdentityRequirements.Anonymous,
            diligenceRequirements: "",
            aggregateBountyCapUsd: 0
        });

        // create + setCommitmentWindow(default) + adopt
        address agreement =
            createAndAdoptAgreement(details, msg.sender, keccak256(abi.encodePacked("agreement-v1", msg.sender, vault)));

        vm.stopBroadcast();

        console.log("Agreement created, commitment window set, and adopted:", agreement);
        console.log("\n--- Add to your .env ---");
        console.log("AGREEMENT_ADDRESS=%s", agreement);
    }
}
