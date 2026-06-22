// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";
import {Exploit} from "../src/Exploit.sol";

contract ReentrancyTest is Test {
    uint256 constant VAULT_SEED = 1_000e18;
    uint256 constant ATTACKER_SEED = 100e18; // Attacker.SEED_AMOUNT

    function test_vaultDeploysAndSeedsItsOwnToken() public {
        VulnerableVault vault = new VulnerableVault(VAULT_SEED);
        IERC20 token = IERC20(address(vault.TOKEN()));
        assertEq(token.balanceOf(address(vault)), VAULT_SEED);
    }

    function test_exploitDrainsVaultInOneDeploy() public {
        VulnerableVault vault = new VulnerableVault(VAULT_SEED);
        IERC20 token = IERC20(address(vault.TOKEN()));

        address whitehat = makeAddr("whitehat");
        address recovery = makeAddr("recovery");

        // Deploying Exploit IS the whole attack. moderator=0 skips the (separate)
        // approve step; this asserts the reentrancy drain + bounty split.
        vm.prank(whitehat);
        new Exploit(address(vault), recovery, address(0), address(0));

        // The attacker's seed is excluded from the bounty base: the bounty is 10% of the
        // recovered PROTOCOL funds (VAULT_SEED), and the whitehat reclaims their own seed.
        uint256 recovered = VAULT_SEED;
        uint256 bounty = recovered * 1_000 / 10_000;
        assertEq(token.balanceOf(address(vault)), 0, "vault drained");
        assertEq(token.balanceOf(recovery), recovered - bounty, "90% of recovered returned to protocol");
        assertEq(token.balanceOf(whitehat), bounty + ATTACKER_SEED, "bounty + reclaimed seed to whitehat");
    }
}
