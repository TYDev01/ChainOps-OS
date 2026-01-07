// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "./Errors.sol";
import {Roles} from "./Roles.sol";

/// @title AgentManager
/// @notice Manages trusted automation agents and their scopes.
/// @dev Invariant: agents cannot pull funds and only registered scopes are enabled.
contract AgentManager is Roles {
    enum Scope {
        READ,
        ALERT,
        EXECUTE
    }

    struct Agent {
        bool enabled;
        uint256 scopes;
        bytes32 metadataHash;
    }

    mapping(address => Agent) private agents;

    event AgentRegistered(address indexed agent, bytes32 metadataHash);
    event AgentEnabled(address indexed agent);
    event AgentDisabled(address indexed agent);
    event AgentScopeUpdated(address indexed agent, uint256 scopes);

    constructor(address admin) Roles(admin) {}

    function registerAgent(address agent, bytes32 metadataHash) external onlyRole(AGENT_ADMIN) {
        if (agent == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (agents[agent].metadataHash != bytes32(0)) {
            revert Errors.AlreadyRegistered();
        }
        agents[agent] = Agent({enabled: true, scopes: 0, metadataHash: metadataHash});
        emit AgentRegistered(agent, metadataHash);
    }
}
