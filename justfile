set dotenv-load

RPC := "battlechain"

# ── Protocol role ──────────────────────────────────────────────────────────────

# Step 1: Deploy MockToken + VulnerableVault, seed the vault
setup:
    forge script script/Setup.s.sol --rpc-url {{RPC}} --broadcast -vvv

# Step 2: Create Safe Harbor agreement (requires VAULT_ADDRESS in .env)
create-agreement:
    forge script script/CreateAgreement.s.sol --rpc-url {{RPC}} --broadcast -vvv

# Step 3: Request attack mode (requires AGREEMENT_ADDRESS in .env)
request-attack-mode:
    forge script script/RequestAttackMode.s.sol --rpc-url {{RPC}} --broadcast -vvv

# ── Whitehat role ──────────────────────────────────────────────────────────────

# Step 4: Execute the attack (requires DAO approval first)
attack:
    forge script script/Attack.s.sol --rpc-url {{RPC}} --broadcast -vvv

# ── Utilities ──────────────────────────────────────────────────────────────────

# Check agreement state (2=ATTACK_REQUESTED, 3=UNDER_ATTACK)
check-state:
    cast call $ATTACK_REGISTRY "getAgreementState(address)(uint8)" $AGREEMENT_ADDRESS \
        --rpc-url http://testnet.battlechain.com:3051

build:
    forge build

test:
    forge test -vvv
