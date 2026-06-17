set dotenv-load

import "lib/battlechain-lib/battlechain.just"

# Network selection (from battlechain.just): defaults to Testnet (chain 627). Target
# Mainnet (chain 626) by prefixing any recipe with NETWORK=mainnet, e.g.
#   NETWORK=mainnet just setup
# RPC, chain id, and verify flags all follow NETWORK via bc-rpc / bc-chain-id / bc-verify-flags.
#
# Caveat: the permissionless MockRegistryModerator (used by `approve-attack-mode`) is testnet-only.
# On mainnet the registry moderator is access-controlled, so attack-mode approval happens off this
# repo (a moderator multisig). `approve-attack-mode` therefore refuses to run on mainnet.
RPC    := bc-rpc
ACCT   := "battlechain"

# Attack registry address per network (from battlechain-lib BCConfig.sol), used by `check-state`.
ATTACK_REGISTRY_ADDR := if NETWORK == "mainnet" { "0x24876e481eC7198CAC95af739Df2a852CE65A415" } else { "0x22134e878c409a0Eab7259d873b38e26Ca966d3C" }

# ── Protocol role ──────────────────────────────────────────────────────────────

# Step 1: Deploy MockToken + VulnerableVault, seed the vault
setup:
    forge script script/Setup.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

# Step 2: Create Safe Harbor agreement (requires VAULT_ADDRESS in .env)
create-agreement:
    forge script script/CreateAgreement.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

# Step 3: Request attack mode (requires AGREEMENT_ADDRESS in .env)
request-attack-mode:
    forge script script/RequestAttackMode.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

# Step 3b: Approve the request via the permissionless MockRegistryModerator (TESTNET ONLY, requires AGREEMENT_ADDRESS in .env)
approve-attack-mode:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "${NETWORK:-testnet}" = "mainnet" ]; then
        echo "approve-attack-mode is testnet-only."
        echo "On mainnet the registry moderator is access-controlled (a moderator multisig), so there is"
        echo "no self-service approval. After 'NETWORK=mainnet just request-attack-mode', ask a moderator"
        echo "multisig signer to approve the request; then run 'NETWORK=mainnet just attack'."
        exit 1
    fi
    forge script script/ApproveAttackMode.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

# ── Whitehat role ──────────────────────────────────────────────────────────────

# Step 4: Execute the attack (requires DAO approval first)
attack:
    forge script script/Attack.s.sol --rpc-url {{RPC}} --broadcast -vvv --account {{ACCT}} --sender $SENDER_ADDRESS --skip-simulation

# ── Browser wallet (AI-initiated, user-approved) ─────────────────────────────

# Step 1: Deploy MockToken + VulnerableVault, seed the vault (browser wallet)
setup-browser:
    forge script script/Setup.s.sol --rpc-url {{RPC}} --broadcast -vvv --browser --chain {{bc-chain-id}} --skip-simulation --verify {{bc-verify-flags}}

# Step 2: Create Safe Harbor agreement (browser wallet)
create-agreement-browser:
    forge script script/CreateAgreement.s.sol --rpc-url {{RPC}} --broadcast -vvv --browser --chain {{bc-chain-id}} --skip-simulation --verify {{bc-verify-flags}}

# Step 3: Request attack mode (browser wallet)
request-attack-mode-browser:
    forge script script/RequestAttackMode.s.sol --rpc-url {{RPC}} --broadcast -vvv --browser --chain {{bc-chain-id}} --skip-simulation --verify {{bc-verify-flags}}

# Step 4: Execute the attack (browser wallet)
attack-browser:
    forge script script/Attack.s.sol --rpc-url {{RPC}} --broadcast -vvv --browser --chain {{bc-chain-id}} --skip-simulation --verify {{bc-verify-flags}}

# ── Verification ──────────────────────────────────────────────────────────────

# Verify all contracts from the Setup broadcast
verify-setup:
    just bc-verify-broadcast script/Setup.s.sol

# ── Utilities ──────────────────────────────────────────────────────────────────

# Generate a random private key and import it as the 'battlechain' keystore account
generate-key:
    cast wallet import battlechain --private-key 0x$(openssl rand -hex 32)

# Check agreement state (2=ATTACK_REQUESTED, 3=UNDER_ATTACK, 5=PRODUCTION)
check-state:
    cast call {{ATTACK_REGISTRY_ADDR}} "getAgreementState(address)(uint8)" $AGREEMENT_ADDRESS \
        --rpc-url {{RPC}}

build:
    forge build

test:
    forge test -vvv
