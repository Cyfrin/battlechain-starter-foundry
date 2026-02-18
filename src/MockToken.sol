// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Hook interface for contracts that want custom logic on incoming transfers.
interface ITransferHook {
    function onTokenTransfer(address from, uint256 amount) external;
}

/// @title MockToken
/// @notice A mintable ERC20 where any user can register a "transfer hook" contract.
///
/// @dev When tokens are transferred to an address that has a registered hook,
///      the token calls `onTokenTransfer` on that hook contract after the
///      transfer completes. This lets users plug in arbitrary logic that
///      runs whenever they receive tokens — and is what makes the CEI
///      violation in VulnerableVault exploitable via reentrancy.
contract MockToken is ERC20 {
    /// @notice Maps a user address to their chosen hook contract.
    ///         When tokens are transferred TO the user, the hook is called.
    mapping(address => address) public transferHooks;

    event TransferHookSet(address indexed user, address indexed hook);

    constructor() ERC20("BattleChain Demo Token", "BCDT") {}

    /// @notice Anyone can mint. This is intentional for the tutorial.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Register a hook contract that is called when you receive tokens.
    /// @param hook The contract to call on incoming transfers (address(0) to remove).
    function setTransferHook(address hook) external {
        transferHooks[msg.sender] = hook;
        emit TransferHookSet(msg.sender, hook);
    }

    /// @dev Overrides transfer to call the recipient's hook (if set) after moving tokens.
    function transfer(address to, uint256 amount) public override returns (bool) {
        bool success = super.transfer(to, amount);

        address hook = transferHooks[to];
        if (hook != address(0)) {
            ITransferHook(hook).onTokenTransfer(msg.sender, amount);
        }

        return success;
    }
}
