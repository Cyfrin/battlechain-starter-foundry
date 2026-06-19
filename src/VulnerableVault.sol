// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Minimal interface for MockToken's open mint, used to self-seed on deploy.
interface IMintableToken {
    function mint(address to, uint256 amount) external;
}

/// @title VulnerableVault
/// @notice A simple token vault with a deliberate CEI (Checks-Effects-Interactions) violation.
///
/// @dev THE VULNERABILITY
///      `withdrawAll()` performs the token transfer (Interaction) BEFORE zeroing
///      the caller's balance (Effect). If the token triggers a callback on the
///      recipient during transfer, an attacker can re-enter `withdrawAll()`
///      before the balance is cleared — draining the entire vault.
///
///      The correct pattern (CEI) would be:
///          balances[msg.sender] = 0;                   // Effect first
///          token.transfer(msg.sender, amount);         // Interaction second
contract VulnerableVault {
    IERC20 public immutable TOKEN;
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /// @param _token The vault's deposit/withdraw token.
    /// @param _seed  Tokens minted to the vault on deployment to represent protocol
    ///               liquidity, so deploying also seeds it (MockToken allows anyone
    ///               to mint). Tutorial convenience — real vaults don't self-mint.
    constructor(address _token, uint256 _seed) {
        TOKEN = IERC20(_token);
        if (_seed > 0) {
            IMintableToken(_token).mint(address(this), _seed);
        }
    }

    /// @notice Deposit tokens into the vault.
    function deposit(uint256 amount) external {
        TOKEN.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    /// @notice Withdraw all of your deposited tokens.
    /// @dev VULNERABLE: The token transfer happens before the balance is cleared.
    ///      If the token calls a hook on the recipient, re-entry is possible
    ///      before `balances` is updated — enabling repeated withdrawals.
    function withdrawAll() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "nothing to withdraw");

        // ❌ INTERACTION before EFFECT
        TOKEN.transfer(msg.sender, amount); // external call — may trigger a hook

        // ❌ Effect happens here — but re-entrant calls already passed the check above
        balances[msg.sender] = 0;

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Returns the deposited balance for a user.
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
