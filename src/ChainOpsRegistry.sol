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

    function computeId(bytes32 kind, address owner, bytes32 metadataHash) public pure returns (bytes32) {
        if (owner == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (kind == bytes32(0)) {
            revert Errors.InvalidId();
        }
        return keccak256(abi.encodePacked(kind, owner, metadataHash));
    }

    function registerAnalyticsModule(bytes32 id, address owner, bytes32 metadataHash) external onlyRole(REGISTRY_ADMIN) {
        if (id == bytes32(0)) {
            revert Errors.InvalidId();
        }
        if (owner == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (analyticsModules[id].owner != address(0)) {
            revert Errors.AlreadyRegistered();
        }
        analyticsModules[id] = Entry({owner: owner, enabled: true, metadataHash: metadataHash});
        emit AnalyticsModuleRegistered(id, owner, metadataHash);
    }

    function registerAutomationRule(bytes32 id, address owner, bytes32 metadataHash) external onlyRole(RULE_ADMIN) {
        if (id == bytes32(0)) {
            revert Errors.InvalidId();
        }
        if (owner == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (automationRules[id].owner != address(0)) {
            revert Errors.AlreadyRegistered();
        }
        automationRules[id] = Entry({owner: owner, enabled: true, metadataHash: metadataHash});
        emit AutomationRuleRegistered(id, owner, metadataHash);
    }

    function registerAgent(bytes32 id, address owner, bytes32 metadataHash) external onlyRole(AGENT_ADMIN) {
        if (id == bytes32(0)) {
            revert Errors.InvalidId();
        }
        if (owner == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (agents[id].owner != address(0)) {
            revert Errors.AlreadyRegistered();
        }
        agents[id] = Entry({owner: owner, enabled: true, metadataHash: metadataHash});
        emit AgentRegistered(id, owner, metadataHash);
    }

    function getAnalyticsModule(bytes32 id) external view returns (Entry memory) {
        return analyticsModules[id];
    }

    function getAutomationRule(bytes32 id) external view returns (Entry memory) {
        return automationRules[id];
    }

    function getAgent(bytes32 id) external view returns (Entry memory) {
        return agents[id];
    }

    function setAnalyticsModuleStatus(bytes32 id, bool enabled) external onlyRole(REGISTRY_ADMIN) {
        if (analyticsModules[id].owner == address(0)) {
            revert Errors.NotRegistered();
        }
        analyticsModules[id].enabled = enabled;
        emit AnalyticsModuleRegistered(id, analyticsModules[id].owner, analyticsModules[id].metadataHash);
    }

    function setAutomationRuleStatus(bytes32 id, bool enabled) external onlyRole(RULE_ADMIN) {
        if (automationRules[id].owner == address(0)) {
            revert Errors.NotRegistered();
        }
        automationRules[id].enabled = enabled;
        emit AutomationRuleRegistered(id, automationRules[id].owner, automationRules[id].metadataHash);
    }
}
