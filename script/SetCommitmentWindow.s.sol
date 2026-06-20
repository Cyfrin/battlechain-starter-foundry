// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {BCSafeHarbor} from "battlechain-lib/BCSafeHarbor.sol";

/// @notice Optional (Protocol): Extend the agreement's commitment window, locking
/// the terms for a period. A single transaction. The quickstart demo skips this —
/// it's here for protocols that want to commit to their terms for real.
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
