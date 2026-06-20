// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {BCSafeHarbor} from "battlechain-lib/BCSafeHarbor.sol";

/// @notice (Protocol) Extend the agreement's commitment window, locking its terms.
/// REQUIRED before attack mode: the AttackRegistry rejects `requestUnderAttack` until
/// the agreement's commitment window is set (`AttackRegistry__InsufficientCommitment`).
/// A single transaction.
///
/// Prerequisites — set in .env:
///   AGREEMENT_ADDRESS (from CreateAgreement)
///
/// Usage:
///   just set-commitment-window            # keystore
///   just set-commitment-window-browser    # your own wallet (MetaMask/Trezor)
contract SetCommitmentWindow is BCSafeHarbor {
    uint256 constant COMMITMENT_WINDOW_DAYS = 30;

    function run() external {
        address agreement = vm.envAddress("AGREEMENT_ADDRESS");

        vm.startBroadcast();
        setCommitmentWindow(agreement, COMMITMENT_WINDOW_DAYS);
        vm.stopBroadcast();

        console.log("Commitment window set to", COMMITMENT_WINDOW_DAYS, "days for:", agreement);
    }
}
