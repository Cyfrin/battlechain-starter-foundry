// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {BCSafeHarbor} from "battlechain-lib/BCSafeHarbor.sol";

/// @notice Step 4 (Protocol): Adopt the agreement in the BattleChain Safe Harbor
/// Registry — a single transaction. This is what makes the agreement (and its
/// in-scope contracts) live for attack mode.
///
/// Prerequisites — set in .env:
///   AGREEMENT_ADDRESS (from CreateAgreement)
///
/// Usage:
///   just adopt-agreement            # keystore
///   just adopt-agreement-browser    # your own wallet (MetaMask/Trezor)
contract AdoptAgreement is BCSafeHarbor {
    function run() external {
        address agreement = vm.envAddress("AGREEMENT_ADDRESS");

        vm.startBroadcast();
        adoptAgreement(agreement);
        vm.stopBroadcast();

        console.log("Safe Harbor adopted for agreement:", agreement);
    }
}
