// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Centralized custom errors for ChainOps core contracts.
library Errors {
    error Unauthorized();
    error InvalidAddress();
    error InvalidRole();
    error AlreadyRegistered();
    error NotRegistered();
    error InvalidId();
    error Disabled();
    error ScopeNotAllowed();
    error RuleNotFound();
    error TargetNotWhitelisted();
    error SelectorNotWhitelisted();
    error GasLimitExceeded();
    error Reentrancy();
}
