// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IAttackRegistry} from "../src/interfaces/IBattleChain.sol";

/// @notice Step 3 (Protocol): Submit the attack mode request for DAO review.
///
/// Prerequisites — set in .env:
///   AGREEMENT_ADDRESS
///
/// Usage:
///   forge script script/RequestAttackMode.s.sol --rpc-url battlechain --broadcast
///
/// After running, wait for DAO approval. Check status with:
///   cast call $ATTACK_REGISTRY "getAgreementState(address)(uint8)" $AGREEMENT_ADDRESS \
///     --rpc-url http://testnet.battlechain.com:3051
///   # 2 = ATTACK_REQUESTED, 3 = UNDER_ATTACK (approved)
contract RequestAttackMode is Script {
    address constant ATTACK_REGISTRY = 0x9E62988ccA776ff6613Fa68D34c9AB5431Ce57e1;

    function run() external {
        uint256 deployerKey  = vm.envUint("PRIVATE_KEY");
        address agreement    = vm.envAddress("AGREEMENT_ADDRESS");

        vm.startBroadcast(deployerKey);

        IAttackRegistry(ATTACK_REGISTRY).requestUnderAttack(agreement);

        vm.stopBroadcast();

        console.log("Attack mode requested for agreement:", agreement);
        console.log("State is now ATTACK_REQUESTED (2) - awaiting DAO approval.");
        console.log("Once approved, state moves to UNDER_ATTACK (3).");
    }
}
