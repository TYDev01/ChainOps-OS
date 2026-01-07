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

    function whitelistTarget(address target, bytes4 selector, bool allowed) external onlyRole(EXECUTOR) {
        if (target == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (selector == bytes4(0)) {
            revert Errors.InvalidId();
        }
        whitelist[target][selector] = allowed;
        emit TargetWhitelisted(target, selector, allowed);
    }

    function getWhitelist(address target, bytes4 selector) external view returns (bool) {
        return whitelist[target][selector];
    }

    function execute(ExecutionTypes.ExecutionRequest calldata request) external onlyRole(EXECUTOR) returns (ExecutionTypes.ExecutionReceipt memory) {
        if (executed[request.requestId]) {
            revert Errors.AlreadyRegistered();
        }
        if (!whitelist[request.target][bytes4(request.callData)]) {
            revert Errors.TargetNotWhitelisted();
        }
        if (request.gasLimit == 0 || request.gasLimit > block.gaslimit) {
            revert Errors.GasLimitExceeded();
        }
        if (locked) {
            revert Errors.Reentrancy();
        }
        locked = true;
        (bool success, bytes memory returnData) = request.target.call{value: request.value, gas: request.gasLimit}(request.callData);
        locked = false;

        bytes32 returnDataHash = keccak256(returnData);
        executed[request.requestId] = true;

        ExecutionTypes.ExecutionReceipt memory receipt = ExecutionTypes.ExecutionReceipt({
            requestId: request.requestId,
            ruleId: request.ruleId,
            target: request.target,
            success: success,
            returnDataHash: returnDataHash,
            gasUsed: request.gasLimit,
            executedBy: msg.sender,
            executedAt: block.timestamp
        });
        emit Executed(request.requestId, request.ruleId, request.target, success);
        return receipt;
    }
}
