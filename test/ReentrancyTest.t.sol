// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";
import {Attacker} from "../src/Attacker.sol";

contract ReentrancyTest is Test {
    MockToken public token;
    VulnerableVault public vault;

    address deployer = makeAddr("deployer");
    address victim = makeAddr("victim");
    address attackerEOA = makeAddr("attacker");
    address recovery = makeAddr("recovery");

    uint256 constant VAULT_SEED = 1_000e18;
    uint256 constant ATTACK_SEED = 100e18;
    uint256 constant BOUNTY_BPS = 1_000; // 10%

    function setUp() public {
        // Deploy token and vault
        token = new MockToken();
        vault = new VulnerableVault(address(token));

        // Seed vault with protocol liquidity
        token.mint(deployer, VAULT_SEED);
        vm.startPrank(deployer);
        token.approve(address(vault), VAULT_SEED);
        vault.deposit(VAULT_SEED);
        vm.stopPrank();
    }

    function test_reentrancyDrainsVault() public {
        uint256 vaultBefore = token.balanceOf(address(vault));
        assertEq(vaultBefore, VAULT_SEED);

        // Attacker deploys exploit contract and drains the vault
        vm.startPrank(attackerEOA);
        Attacker attacker = new Attacker(address(vault), address(token), recovery, BOUNTY_BPS);
        attacker.attack(ATTACK_SEED);
        vm.stopPrank();

        // Vault is empty
        assertEq(token.balanceOf(address(vault)), 0);

        // 90% returned to recovery, 10% kept as bounty
        uint256 total = VAULT_SEED + ATTACK_SEED;
        assertEq(token.balanceOf(recovery), total * 9_000 / 10_000);
        assertEq(token.balanceOf(attackerEOA), total * BOUNTY_BPS / 10_000);

        // Deployer's vault balance is still recorded but unwithdrawable
        assertEq(vault.getBalance(deployer), VAULT_SEED);
        vm.prank(deployer);
        vm.expectRevert();
        vault.withdrawAll();
    }
}
