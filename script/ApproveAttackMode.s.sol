// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

interface IMockRegistryModerator {
    function approveAttack(address agreementAddress) external;
}

/// @notice Step 3b (Testnet only): Approve the attack mode request via the permissionless MockRegistryModerator.
///
/// On testnet the DAO role is filled by a permissionless mock moderator — anyone can call it.
/// This skips the real DAO approval wait and transitions the agreement directly to UNDER_ATTACK (3).
///
/// Prerequisites — set in .env:
///   SENDER_ADDRESS, AGREEMENT_ADDRESS
///
/// Usage:
///   just approve-attack-mode
///
contract ApproveAttackMode is Script {
    address private constant MOCK_REGISTRY_MODERATOR = 0x1bC64E6F187a47D136106784f4E9182801535BD3;

    function run() external {
        address agreement = vm.envAddress("AGREEMENT_ADDRESS");

        vm.startBroadcast();

        IMockRegistryModerator(MOCK_REGISTRY_MODERATOR).approveAttack(agreement);

        vm.stopBroadcast();

        console.log("Attack approved for agreement:", agreement);
        console.log("State is now UNDER_ATTACK (3) - ready to run: just attack");
    }
}
