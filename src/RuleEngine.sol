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
}
