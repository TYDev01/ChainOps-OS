// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "./Errors.sol";
import {Roles} from "./Roles.sol";
import {ExecutionTypes} from "./ExecutionTypes.sol";

/// @title ExecutionRouter
/// @notice Safe execution gateway for pre-approved targets.
/// @dev Invariant: only whitelisted target+selector pairs can be executed.
contract ExecutionRouter is Roles {
    mapping(address => mapping(bytes4 => bool)) private whitelist;
    mapping(bytes32 => bool) private executed;
    bool private locked;

    event TargetWhitelisted(address indexed target, bytes4 indexed selector, bool allowed);
    event Executed(bytes32 indexed requestId, bytes32 indexed ruleId, address indexed target, bool success);

    constructor(address admin) Roles(admin) {}
}
