set dotenv-load

import "lib/battlechain-lib/battlechain.just"

RPC    := "https://testnet.battlechain.com"
ACCT   := "battlechain"

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

# Check agreement state (2=ATTACK_REQUESTED, 3=UNDER_ATTACK)
check-state:
    cast call $ATTACK_REGISTRY "getAgreementState(address)(uint8)" $AGREEMENT_ADDRESS \
        --rpc-url https://testnet.battlechain.com

build:
    forge build

test:
    forge test -vvv
