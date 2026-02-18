// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";
import {Attack} from "../script/Attack.s.sol";

contract ReentrancyTest is Test {
    MockToken public token;
    VulnerableVault public vault;

    address deployer = makeAddr("deployer");
    address recovery = makeAddr("recovery");
    address attackerEOA;
    uint256 attackerKey;

    uint256 constant VAULT_SEED = 1_000e18;

    function setUp() public {
        (attackerEOA, attackerKey) = makeAddrAndKey("attacker");

        // Deploy token and vault
        token = new MockToken();
        vault = new VulnerableVault(address(token));

        // Seed vault with protocol liquidity
        token.mint(deployer, VAULT_SEED);
        vm.startPrank(deployer);
        token.approve(address(vault), VAULT_SEED);
        vault.deposit(VAULT_SEED);
        vm.stopPrank();

        // Set env vars for the script
        vm.setEnv("PRIVATE_KEY", vm.toString(attackerKey));
        vm.setEnv("TOKEN_ADDRESS", vm.toString(address(token)));
        vm.setEnv("VAULT_ADDRESS", vm.toString(address(vault)));
        vm.setEnv("RECOVERY_ADDRESS", vm.toString(recovery));
    }

    function test_reentrancyDrainsVault() public {
        uint256 vaultBefore = token.balanceOf(address(vault));
        assertEq(vaultBefore, VAULT_SEED);

        // Run the attack script exactly as it would be run on-chain
        Attack attack = new Attack();
        attack.run();

        // Vault is empty
        assertEq(token.balanceOf(address(vault)), 0);

        // 90% returned to recovery, 10% kept as bounty
        uint256 total = VAULT_SEED + 100e18; // SEED_AMOUNT from Attack.s.sol
        assertEq(token.balanceOf(recovery), total * 9_000 / 10_000);
        assertEq(token.balanceOf(attackerEOA), total * 1_000 / 10_000); // BOUNTY_BPS = 1_000

        // Deployer's vault balance is still recorded but unwithdrawable
        assertEq(vault.getBalance(deployer), VAULT_SEED);
        vm.prank(deployer);
        vm.expectRevert();
        vault.withdrawAll();
    }
}
