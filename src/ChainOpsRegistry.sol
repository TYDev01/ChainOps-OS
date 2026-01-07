// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "./Errors.sol";
import {Roles} from "./Roles.sol";

/// @title ChainOpsRegistry
/// @notice Global registry for ChainOps components.
/// @dev Invariant: registry entries are immutable by id and only role holders can register.
contract ChainOpsRegistry is Roles {
    struct Entry {
        address owner;
        bool enabled;
        bytes32 metadataHash;
    }

    mapping(bytes32 => Entry) private analyticsModules;
    mapping(bytes32 => Entry) private automationRules;
    mapping(bytes32 => Entry) private agents;

    event AnalyticsModuleRegistered(bytes32 indexed id, address indexed owner, bytes32 metadataHash);
    event AutomationRuleRegistered(bytes32 indexed id, address indexed owner, bytes32 metadataHash);
    event AgentRegistered(bytes32 indexed id, address indexed owner, bytes32 metadataHash);

    constructor(address admin) Roles(admin) {}
}
