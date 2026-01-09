// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "./Errors.sol";

/// @notice Role definitions for ChainOps contracts.
abstract contract Roles {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant REGISTRY_ADMIN = keccak256("REGISTRY_ADMIN");
    bytes32 public constant AGENT_ADMIN = keccak256("AGENT_ADMIN");
    bytes32 public constant RULE_ADMIN = keccak256("RULE_ADMIN");
    bytes32 public constant EXECUTOR = keccak256("EXECUTOR");

    mapping(bytes32 => mapping(address => bool)) private roles;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) {
            revert Errors.Unauthorized();
        }
        _;
    }

    /// @notice Initializes the admin role.
    constructor(address admin) {
        if (admin == address(0)) {
            revert Errors.InvalidAddress();
        }
        roles[DEFAULT_ADMIN_ROLE][admin] = true;
        emit RoleGranted(DEFAULT_ADMIN_ROLE, admin, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return roles[role][account];
    }
}
