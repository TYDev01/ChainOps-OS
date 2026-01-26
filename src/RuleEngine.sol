// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "./Errors.sol";
import {Roles} from "./Roles.sol";
import {RuleTypes} from "./RuleTypes.sol";

interface IAgentManager {
    enum Scope {
        READ,
        ALERT,
        EXECUTE
    }

    function hasScope(address agent, Scope scope) external view returns (bool);
}

interface IChainOpsRegistry {
    struct Entry {
        address owner;
        bool enabled;
        bytes32 metadataHash;
    }

    function getAutomationRule(bytes32 id) external view returns (Entry memory);
}

/// @title RuleEngine
/// @notice Defines and evaluates automation rules.
/// @dev Invariant: rules are data-only and evaluation emits events.
contract RuleEngine is Roles {
    mapping(bytes32 => RuleTypes.Rule) private rules;
    mapping(bytes32 => uint256) private lastValues;
    mapping(bytes32 => bool) private hasLastValue;
    mapping(bytes32 => FrequencyState) private frequencyStates;
    address public agentManager;
    address public registry;
    uint256[44] private __gap;

    struct FrequencyState {
        uint256 count;
        uint256 windowStart;
    }

    event RuleRegistered(bytes32 indexed ruleId, RuleTypes.RuleCategory category);
    event RuleEvaluated(bytes32 indexed ruleId, address indexed triggeredBy, bool passed, bytes32 payloadHash);
    event RuleStatusUpdated(bytes32 indexed ruleId, bool enabled);
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

    function registerRule(RuleTypes.Rule calldata rule) external onlyRole(RULE_ADMIN) {
        if (rule.id == bytes32(0)) {
            revert Errors.InvalidId();
        }
        if (rule.category == RuleTypes.RuleCategory.FREQUENCY) {
            if (rule.timeWindow == 0 || rule.frequency == 0) {
                revert Errors.InvalidId();
            }
        }
        if (rules[rule.id].id != bytes32(0)) {
            revert Errors.AlreadyRegistered();
        }
        rules[rule.id] = rule;
        emit RuleRegistered(rule.id, rule.category);
    }

    function getRule(bytes32 ruleId) external view returns (RuleTypes.Rule memory) {
        return rules[ruleId];
    }

    function evaluate(bytes32 ruleId, uint256 value, bytes32 payloadHash) external returns (bool) {
        if (agentManager != address(0)) {
            bool allowed = IAgentManager(agentManager).hasScope(msg.sender, IAgentManager.Scope.READ);
            if (!allowed) {
                revert Errors.ScopeNotAllowed();
            }
        }
        if (registry != address(0)) {
            IChainOpsRegistry.Entry memory entry = IChainOpsRegistry(registry).getAutomationRule(ruleId);
            if (!entry.enabled) {
                revert Errors.Disabled();
            }
        }
        RuleTypes.Rule memory rule = rules[ruleId];
        if (rule.id == bytes32(0)) {
            revert Errors.RuleNotFound();
        }
        if (!rule.enabled) {
            revert Errors.Disabled();
        }

        bool passed;
        if (rule.category == RuleTypes.RuleCategory.THRESHOLD) {
            passed = _compare(value, rule.threshold, rule.comparison);
        } else if (rule.category == RuleTypes.RuleCategory.DELTA) {
            if (!hasLastValue[ruleId]) {
                hasLastValue[ruleId] = true;
                lastValues[ruleId] = value;
                passed = false;
            } else {
                uint256 prev = lastValues[ruleId];
                uint256 delta = value > prev ? value - prev : prev - value;
                lastValues[ruleId] = value;
                passed = _compare(delta, rule.threshold, rule.comparison);
            }
        } else if (rule.category == RuleTypes.RuleCategory.FREQUENCY) {
            if (rule.timeWindow == 0 || rule.frequency == 0) {
                revert Errors.InvalidId();
            }
            FrequencyState memory state = frequencyStates[ruleId];
            if (state.windowStart == 0 || block.timestamp > state.windowStart + rule.timeWindow) {
                state.windowStart = block.timestamp;
                state.count = 1;
            } else {
                state.count += 1;
            }
            frequencyStates[ruleId] = state;
            passed = _compare(state.count, rule.frequency, rule.comparison);
        } else {
            revert Errors.InvalidId();
        }
        emit RuleEvaluated(ruleId, msg.sender, passed, payloadHash);
        return passed;
    }

    function setRuleStatus(bytes32 ruleId, bool enabled) external onlyRole(RULE_ADMIN) {
        if (rules[ruleId].id == bytes32(0)) {
            revert Errors.RuleNotFound();
        }
        rules[ruleId].enabled = enabled;
        emit RuleStatusUpdated(ruleId, enabled);
    }

    function _compare(uint256 lhs, uint256 rhs, RuleTypes.Comparison op) internal pure returns (bool) {
        if (op == RuleTypes.Comparison.GT) {
            return lhs > rhs;
        }
        if (op == RuleTypes.Comparison.GTE) {
            return lhs >= rhs;
        }
        if (op == RuleTypes.Comparison.LT) {
            return lhs < rhs;
        }
        if (op == RuleTypes.Comparison.LTE) {
            return lhs <= rhs;
        }
        if (op == RuleTypes.Comparison.EQ) {
            return lhs == rhs;
        }
        if (op == RuleTypes.Comparison.NEQ) {
            return lhs != rhs;
        }
        revert Errors.InvalidId();
    }
}
