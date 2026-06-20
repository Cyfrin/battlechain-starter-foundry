// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {BCDeploy} from "battlechain-lib/BCDeploy.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";

interface IVaultToken {
    function TOKEN() external view returns (address);
}

/// @notice Step 1 (Protocol): Deploy the vulnerable protocol in ONE transaction.
/// The VulnerableVault constructor deploys its own MockToken and seeds itself, so a
/// single signature stands up both contracts. The vault is deployed via the
/// BattleChainDeployer (registered); the token is created by the vault.
///
/// Usage:
///   just deploy-protocol            # keystore
///   just deploy-protocol-browser    # your own wallet (MetaMask/Trezor)
///
/// After running, copy the logged VAULT_ADDRESS and TOKEN_ADDRESS into your .env.
contract DeployProtocol is BCDeploy {
    uint256 constant SEED_AMOUNT = 1_000e18;

    function run() external {
        vm.startBroadcast();
        bytes32 salt = keccak256(abi.encodePacked("vulnerable-vault-v1", msg.sender));
        address vault = bcDeployCreate2(
            salt,
            abi.encodePacked(type(VulnerableVault).creationCode, abi.encode(SEED_AMOUNT))
        );
        vm.stopBroadcast();

        address token = IVaultToken(vault).TOKEN();

        console.log("VulnerableVault deployed + seeded with", SEED_AMOUNT / 1e18, "tokens:", vault);
        console.log("MockToken (deployed by the vault):", token);
        console.log("\n--- Add to your .env ---");
        console.log("VAULT_ADDRESS=%s", vault);
        console.log("TOKEN_ADDRESS=%s", token);
    }
}
