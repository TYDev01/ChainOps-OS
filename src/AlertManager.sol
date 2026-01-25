// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "./Errors.sol";
import {Roles} from "./Roles.sol";

interface IAlertAgentManager {
    enum Scope {
        READ,
        ALERT,
        EXECUTE
    }

    function hasScope(address agent, Scope scope) external view returns (bool);
}

interface IAlertRegistry {
    struct Entry {
        address owner;
        bool enabled;
        bytes32 metadataHash;
    }

    function getAutomationRule(bytes32 id) external view returns (Entry memory);
}

/// @title AlertManager
/// @notice Emits structured on-chain alerts.
/// @dev Invariant: alerts are emitted with rule id, trigger source, and payload hash.
contract AlertManager is Roles {
    struct AlertMetadata {
        bytes32 channel;
        bytes32 metadataHash;
    }

    mapping(bytes32 => AlertMetadata) private alerts;
    address public agentManager;
    address public registry;

    event AlertRegistered(bytes32 indexed alertId, bytes32 indexed channel, bytes32 metadataHash);
    event AlertTriggered(bytes32 indexed ruleId, address indexed triggeredBy, bytes32 payloadHash, bytes32 channel, uint256 timestamp);
    event AgentManagerUpdated(address indexed agentManager);
    event RegistryUpdated(address indexed registry);

    constructor(address admin) Roles(admin) {}

    function setAgentManager(address manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (manager == address(0)) {
            revert Errors.InvalidAddress();
        }
        agentManager = manager;
        emit AgentManagerUpdated(manager);
    }

    function setRegistry(address registryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (registryAddress == address(0)) {
            revert Errors.InvalidAddress();
        }
        registry = registryAddress;
        emit RegistryUpdated(registryAddress);
    }

    function registerAlert(bytes32 alertId, bytes32 channel, bytes32 metadataHash) external onlyRole(REGISTRY_ADMIN) {
        if (alertId == bytes32(0)) {
            revert Errors.InvalidId();
        }
        if (alerts[alertId].metadataHash != bytes32(0)) {
            revert Errors.AlreadyRegistered();
        }
        alerts[alertId] = AlertMetadata({channel: channel, metadataHash: metadataHash});
        emit AlertRegistered(alertId, channel, metadataHash);
    }

    function getAlert(bytes32 alertId) external view returns (AlertMetadata memory) {
        return alerts[alertId];
    }

    function emitAlert(bytes32 ruleId, bytes32 payloadHash, bytes32 alertId) external onlyRole(RULE_ADMIN) {
        if (agentManager != address(0)) {
            bool allowed = IAlertAgentManager(agentManager).hasScope(msg.sender, IAlertAgentManager.Scope.ALERT);
            if (!allowed) {
                revert Errors.ScopeNotAllowed();
            }
        }
        if (ruleId == bytes32(0)) {
            revert Errors.InvalidId();
        }
        AlertMetadata memory meta = alerts[alertId];
        if (meta.metadataHash == bytes32(0)) {
            revert Errors.NotRegistered();
        }
        emit AlertTriggered(ruleId, msg.sender, payloadHash, meta.channel, block.timestamp);
    }
}
