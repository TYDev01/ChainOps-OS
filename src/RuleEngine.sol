// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "./Errors.sol";
import {Roles} from "./Roles.sol";
import {RuleTypes} from "./RuleTypes.sol";

/// @title RuleEngine
/// @notice Defines and evaluates automation rules.
/// @dev Invariant: rules are data-only and evaluation emits events.
contract RuleEngine is Roles {
    mapping(bytes32 => RuleTypes.Rule) private rules;

    event RuleRegistered(bytes32 indexed ruleId, RuleTypes.RuleCategory category);
    event RuleEvaluated(bytes32 indexed ruleId, address indexed triggeredBy, bool passed, bytes32 payloadHash);

    constructor(address admin) Roles(admin) {}

    function registerRule(RuleTypes.Rule calldata rule) external onlyRole(RULE_ADMIN) {
        if (rule.id == bytes32(0)) {
            revert Errors.InvalidId();
        }
        if (rules[rule.id].id != bytes32(0)) {
            revert Errors.AlreadyRegistered();
        }
        rules[rule.id] = rule;
        emit RuleRegistered(rule.id, rule.category);
    }
}
