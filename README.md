# Battlechain Starter

- [About](#about)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
- [Usage — Foundry](#usage--foundry)
  - [Protocol Role](#protocol-role)
  - [Whitehat Role](#whitehat-role)
  - [Utilities](#utilities)
- [Usage — Hardhat](#usage--hardhat)
  - [Protocol Role](#protocol-role-1)
  - [Whitehat Role](#whitehat-role-1)

# About

A starter repo for interacting with the Battlechain Safe Harbor protocol. Includes scripts for deploying a vulnerable vault, creating a Safe Harbor agreement, requesting attack mode, and executing a whitehat rescue.

Supports both **Foundry** and **Hardhat**.

# Getting Started

## Requirements

**Both frameworks:**
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [just](https://github.com/casey/just)

**Foundry:**
- [foundry](https://getfoundry.sh/) — `forge --version`
  - For `just *-browser` targets, forge >= `1.6.0-nightly` (commit `c1cdc6c1`, 2026-03-10) or later

**Hardhat:**
- [Node.js](https://nodejs.org/) >= 22.10.0 (LTS) — use [nvm](https://github.com/nvm-sh/nvm) to manage versions
  - `nvm install --lts && nvm use --lts`

## Installation

```bash
git clone <MY_REPO>
cd <MY_REPO>
```

**Hardhat only** — install Node dependencies:
```bash
npm install
```

## Quickstart

```bash
# Foundry
just build

# Hardhat
just hh-build
```

# Usage — Foundry

Import your key into Foundry's encrypted keystore (once):
```bash
cast wallet import battlechain --interactive
# or generate a fresh key:
just generate-key
```

## Protocol Role

```bash
# Step 1: Deploy MockToken + VulnerableVault, seed the vault
just setup

# Step 2: Create Safe Harbor agreement (requires VAULT_ADDRESS in .env)
just create-agreement

# Step 3: Request attack mode (requires AGREEMENT_ADDRESS in .env)
just request-attack-mode
```

## Whitehat Role

```bash
# Step 4: Execute the attack (requires DAO approval first)
just attack
```

## Utilities

```bash
# Check agreement state (2=ATTACK_REQUESTED, 3=UNDER_ATTACK)
just check-state

# Run tests
just test
```

# Usage — Hardhat

Import your private key into Hardhat's encrypted keystore (once):
```bash
just hh-import-key
# prompts for a master password, then your private key — never stored in plaintext
```

## Protocol Role

```bash
# Step 1: Deploy MockToken + VulnerableVault, seed the vault
# Copy TOKEN_ADDRESS and VAULT_ADDRESS from output into .env
just hh-setup

# Step 2: Create Safe Harbor agreement (requires VAULT_ADDRESS in .env)
# Copy AGREEMENT_ADDRESS from output into .env
just hh-create-agreement

# Step 3: Request attack mode (requires AGREEMENT_ADDRESS in .env)
just hh-request-attack-mode
```

## Whitehat Role

```bash
# Step 4: Execute the attack (requires DAO approval first)
# Requires TOKEN_ADDRESS, VAULT_ADDRESS, RECOVERY_ADDRESS in .env
just hh-attack
```
