// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "./Errors.sol";
import {Roles} from "./Roles.sol";

/// @title AlertManager
/// @notice Emits structured on-chain alerts.
/// @dev Invariant: alerts are emitted with rule id, trigger source, and payload hash.
contract AlertManager is Roles {
    struct AlertMetadata {
        bytes32 channel;
        bytes32 metadataHash;
    }

    mapping(bytes32 => AlertMetadata) private alerts;

    event AlertRegistered(bytes32 indexed alertId, bytes32 indexed channel, bytes32 metadataHash);
    event AlertTriggered(bytes32 indexed ruleId, address indexed triggeredBy, bytes32 payloadHash, bytes32 channel);

    constructor(address admin) Roles(admin) {}

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
}
