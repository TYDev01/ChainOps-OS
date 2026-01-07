// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Role definitions for ChainOps contracts.
abstract contract Roles is AccessControl {
    bytes32 public constant REGISTRY_ADMIN = keccak256("REGISTRY_ADMIN");
    bytes32 public constant AGENT_ADMIN = keccak256("AGENT_ADMIN");
    bytes32 public constant RULE_ADMIN = keccak256("RULE_ADMIN");
    bytes32 public constant EXECUTOR = keccak256("EXECUTOR");

    /// @notice Initializes the admin role.
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }
}
