set dotenv-load

import "lib/battlechain-lib/battlechain.just"

# Recipes target BattleChain Testnet (chain 627): the mock dependencies (e.g. the permissionless
# MockRegistryModerator) are testnet-only. Verification and block explorers exist on both networks.
# The Safe Harbor contracts are also deployed on mainnet (chain 626, https://mainnet.battlechain.com).
RPC    := "https://testnet.battlechain.com"
ACCT   := "battlechain"

# Testnet BattleChain addresses (from battlechain-lib BCConfig).
bc-deployer        := "0x0f75289c6b883b885A1fDF9BCCABE1bbFB094077"
bc-registry        := "0x07E09f67B272aec60eebBfB3D592eC649BDCFEFc"
bc-attack-registry := "0x22134e878c409a0Eab7259d873b38e26Ca966d3C"
bc-factory         := "0xf52CEA27b9E20D03Ec48CDe4fafF8F27565646f2"
bc-moderator       := "0x3DdA228A38b4d7438bBF5D5137c8D1090DcaF6bF"

# ══ Agentic tutorial — browser wallet (MetaMask/Trezor), via cast ════════════
# `forge script --browser` hangs waiting on the wallet to report the receipt, but
# `cast send` takes the hash and polls the chain itself, so it works. Each step is
# ONE `cast send`. Needs Foundry NIGHTLY (`foundryup -i nightly`). The agent runs
# each in the FOREGROUND, waits for you to approve in your wallet, then reads the
# new address from the receipt into .env before the next step.

# Step 1: Deploy the protocol. The vault deploys + seeds its own MockToken; routing
# through the deployer registers the vault with the AttackRegistry (required for
# attack mode). Read VAULT_ADDRESS from the ContractCreation log in the receipt,
# then: cast call <vault> "TOKEN()(address)" --rpc-url {{RPC}}  → TOKEN_ADDRESS.
deploy-protocol-browser:
    #!/usr/bin/env bash
    set -euo pipefail
    SEED=$(cast abi-encode "constructor(uint256)" 1000000000000000000000)
    INITCODE="$(forge inspect VulnerableVault bytecode)${SEED#0x}"
    cast send {{bc-deployer}} "deployCreate(bytes)" "$INITCODE" --browser --rpc-url {{RPC}}

# Step 2: Create the Safe Harbor agreement (requires VAULT_ADDRESS + SENDER_ADDRESS).
# A non-broadcast forge script builds the create() calldata (cheatcodes are fine
# off-broadcast — no browser, no hang); cast sends it. Read AGREEMENT_ADDRESS from
# the receipt's ContractCreation log.
create-agreement-browser:
    #!/usr/bin/env bash
    set -euo pipefail
    CALLDATA=$(forge script script/CreateAgreement.s.sol --sig "genCalldata()" --rpc-url {{RPC}} 2>/dev/null | grep -o "AGREEMENT_CREATE_CALLDATA=0x[0-9a-fA-F]*" | cut -d= -f2)
    test -n "$CALLDATA" || { echo "failed to build create() calldata"; exit 1; }
    cast send {{bc-factory}} --data "$CALLDATA" --browser --rpc-url {{RPC}}

# Step 3: Lock the commitment window. REQUIRED — the AttackRegistry rejects an
# attack-mode request until the agreement's terms are committed. Needs AGREEMENT_ADDRESS.
set-commitment-window-browser:
    cast send "$AGREEMENT_ADDRESS" "extendCommitmentWindow(uint256)" $(( $(date +%s) + 2592000 )) --browser --rpc-url {{RPC}}

# Step 4: Adopt the agreement (requires AGREEMENT_ADDRESS in .env)
adopt-agreement-browser:
    cast send {{bc-registry}} "adoptSafeHarbor(address)" "$AGREEMENT_ADDRESS" --browser --rpc-url {{RPC}}

# Step 5: Request attack mode (requires AGREEMENT_ADDRESS in .env)
request-attack-mode-browser:
    cast send {{bc-attack-registry}} "requestUnderAttack(address)" "$AGREEMENT_ADDRESS" --browser --rpc-url {{RPC}}

# Step 6: Deploy the Exploit — approves attack mode + drains the vault in one tx.
# Requires VAULT_ADDRESS, RECOVERY_ADDRESS, AGREEMENT_ADDRESS in .env.
attack-browser:
    #!/usr/bin/env bash
    set -euo pipefail
    ARGS=$(cast abi-encode "constructor(address,address,address,address)" "$VAULT_ADDRESS" "$RECOVERY_ADDRESS" "$AGREEMENT_ADDRESS" {{bc-moderator}})
    INITCODE="$(forge inspect Exploit bytecode)${ARGS#0x}"
    cast send --browser --rpc-url {{RPC}} --create "$INITCODE"

# ══ Same five steps via keystore (no browser; works on stable Foundry) ═══════

deploy-protocol:
    forge script script/DeployProtocol.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

create-agreement:
    forge script script/CreateAgreement.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

set-commitment-window:
    forge script script/SetCommitmentWindow.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

adopt-agreement:
    forge script script/AdoptAgreement.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

request-attack-mode:
    forge script script/RequestAttackMode.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

attack:
    forge script script/Attack.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

# ══ Verification ═════════════════════════════════════════════════════════════
# Verify the deployed contracts on the BattleChain explorer. bc-verify-broadcast
# parses the broadcast receipts, so it handles CreateX/BCDeploy factory deploys.
# (Browser deploys via cast don't write a broadcast file — verify keystore runs,
# or use `just bc-verify <addr> src/VulnerableVault.sol:VulnerableVault`.)

# Verify MockToken + VulnerableVault from a KEYSTORE deploy (parses the broadcast file).
verify-protocol:
    just bc-verify-broadcast script/DeployProtocol.s.sol

# Verify MockToken + VulnerableVault from a BROWSER (cast) deploy. cast writes no
# broadcast file, so verify by address. Requires VAULT_ADDRESS + TOKEN_ADDRESS in .env.
verify-protocol-browser:
    just bc-verify "$TOKEN_ADDRESS" src/MockToken.sol:MockToken
    forge verify-contract "$VAULT_ADDRESS" src/VulnerableVault.sol:VulnerableVault --chain-id {{bc-chain-id}} {{bc-verify-flags}} --rpc-url {{RPC}} --constructor-args $(cast abi-encode "constructor(uint256)" 1000000000000000000000)

# Verify the Exploit + Attacker (after a keystore attack)
verify-exploit:
    just bc-verify-broadcast script/Attack.s.sol

# ══ Optional / advanced ══════════════════════════════════════════════════════

# Approve attack mode standalone (the attack step folds this in, so usually unneeded).
approve-attack-mode:
    forge script script/ApproveAttackMode.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation
approve-attack-mode-browser:
    cast send {{bc-moderator}} "approveAttack(address)" "$AGREEMENT_ADDRESS" --browser --rpc-url {{RPC}}

# ══ Utilities ════════════════════════════════════════════════════════════════

# Generate a random private key and import it as the 'battlechain' keystore account
generate-key:
    cast wallet import battlechain --private-key 0x$(openssl rand -hex 32)

# Check agreement state (2=ATTACK_REQUESTED, 3=UNDER_ATTACK)
check-state:
    cast call $ATTACK_REGISTRY "getAgreementState(address)(uint8)" $AGREEMENT_ADDRESS \
        --rpc-url {{RPC}}

build:
    forge build

test:
    forge test -vvv
