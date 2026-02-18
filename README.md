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

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`
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
