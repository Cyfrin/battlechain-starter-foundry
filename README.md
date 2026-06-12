# Battlechain Starter

- [About](#about)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Protocol Role](#protocol-role)
  - [Whitehat Role](#whitehat-role)
  - [Utilities](#utilities)

# About

A starter repo for interacting with the Battlechain Safe Harbor protocol. Includes scripts for deploying a vulnerable vault, creating a Safe Harbor agreement, requesting attack mode, and executing a whitehat rescue.

## Networks

| Network             | Chain ID | RPC                              |
| ------------------- | -------- | -------------------------------- |
| BattleChain         | 626      | https://mainnet.battlechain.com  |
| BattleChain Testnet | 627      | https://testnet.battlechain.com  |

The Safe Harbor core contracts (registry, agreement factory, attack registry), CreateX, and the Safe contract suite are deployed on both networks, and both have a block explorer with contract verification: [mainnet](https://explorer.mainnet.battlechain.com/) and [testnet](https://explorer.testnet.battlechain.com/). The flows in this repo target BattleChain Testnet, since the mock dependencies (such as the permissionless `MockRegistryModerator` used to approve attack mode) are testnet-only.

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`
  - For browser wallet targets (`just *-browser`), you need forge >= `1.6.0-nightly` (commit `c1cdc6c1`, 2026-03-10) or later
- [just](https://github.com/casey/just)
  - You'll know you did it right if you can run `just --version` and you see a response like `just 1.x.x`

## Installation

```bash
git clone <MY_REPO>
cd <MY_REPO>
```

## Quickstart

```bash
just build
```

# Usage

## Protocol Role

```bash
# Step 1: Deploy MockToken + VulnerableVault, seed the vault
just setup

# Step 2: Create Safe Harbor agreement (requires VAULT_ADDRESS in .env)
just create-agreement

# Step 3: Request attack mode (requires AGREEMENT_ADDRESS in .env)
just request-attack-mode

# Step 3b: Approve the request via the permissionless MockRegistryModerator (testnet only)
just approve-attack-mode
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
