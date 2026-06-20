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

        uint256 total = VAULT_SEED + ATTACKER_SEED;
        assertEq(token.balanceOf(address(vault)), 0, "vault drained");
        assertEq(token.balanceOf(recovery), total * 9_000 / 10_000, "90% returned to protocol");
        assertEq(token.balanceOf(whitehat), total * 1_000 / 10_000, "10% bounty to whitehat");
    }
}
