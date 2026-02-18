// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/MockToken.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";
import {IBattleChainDeployer} from "../src/interfaces/IBattleChain.sol";

/// @notice Step 1 (Protocol): Deploy MockToken + VulnerableVault, seed the vault.
///
/// Prerequisites — set in .env:
///   PRIVATE_KEY
///
/// Usage:
///   forge script script/Setup.s.sol --rpc-url battlechain --broadcast
///
/// After running, copy the logged addresses into your .env file.
contract Setup is Script {
    // BattleChain testnet
    address constant BATTLECHAIN_DEPLOYER = 0x8f57054CBa2021bEE15631067dd7B7E0B43F17Dc;

    uint256 constant SEED_AMOUNT = 1_000e18; // tokens seeded into vault as "protocol liquidity"

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // 1. Deploy MockToken
        MockToken token = new MockToken();
        console.log("MockToken deployed:", address(token));

        // 2. Deploy VulnerableVault via BattleChainDeployer so it is
        //    automatically registered with the AttackRegistry
        IBattleChainDeployer bcDeployer = IBattleChainDeployer(BATTLECHAIN_DEPLOYER);

        bytes memory bytecode = abi.encodePacked(
            type(VulnerableVault).creationCode,
            abi.encode(address(token)) // constructor arg: token address
        );
        bytes32 salt = keccak256(abi.encodePacked("vulnerable-vault-v1", deployer));

        address vault = bcDeployer.deployCreate2(salt, bytecode);
        console.log("VulnerableVault deployed:", vault);

        // 3. Seed the vault with tokens to represent protocol liquidity
        token.mint(deployer, SEED_AMOUNT);
        token.approve(vault, SEED_AMOUNT);
        VulnerableVault(vault).deposit(SEED_AMOUNT);
        console.log("Vault seeded with", SEED_AMOUNT / 1e18, "tokens");

        vm.stopBroadcast();

        console.log("\n--- Add to your .env ---");
        console.log("TOKEN_ADDRESS=%s", address(token));
        console.log("VAULT_ADDRESS=%s", vault);
    }
}
