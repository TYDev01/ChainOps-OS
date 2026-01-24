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
    mapping(bytes32 => ExecutionTypes.ExecutionRequest) private requests;
    bool private locked;

    event TargetWhitelisted(address indexed target, bytes4 indexed selector, bool allowed);
    event Executed(
        bytes32 indexed requestId,
        bytes32 indexed ruleId,
        address indexed target,
        bool success,
        bytes32 returnDataHash,
        uint256 gasUsed,
        address executedBy,
        uint256 executedAt
    );
    event ExecutionRequested(bytes32 indexed requestId, bytes32 indexed ruleId, address indexed target);

    constructor(address admin) Roles(admin) {}

    function requestExecution(ExecutionTypes.ExecutionRequest calldata request) external onlyRole(EXECUTOR) {
        if (request.requestId == bytes32(0)) {
            revert Errors.InvalidId();
        }
        if (requests[request.requestId].requestId != bytes32(0)) {
            revert Errors.AlreadyRegistered();
        }
        requests[request.requestId] = ExecutionTypes.ExecutionRequest({
            requestId: request.requestId,
            ruleId: request.ruleId,
            target: request.target,
            value: request.value,
            gasLimit: request.gasLimit,
            callData: request.callData,
            requestedBy: msg.sender,
            requestedAt: block.timestamp
        });
        emit ExecutionRequested(request.requestId, request.ruleId, request.target);
    }

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

    function isExecuted(bytes32 requestId) external view returns (bool) {
        return executed[requestId];
    }

    function getRequest(bytes32 requestId) external view returns (ExecutionTypes.ExecutionRequest memory) {
        return requests[requestId];
    }

    function execute(ExecutionTypes.ExecutionRequest calldata request) external onlyRole(EXECUTOR) returns (ExecutionTypes.ExecutionReceipt memory) {
        ExecutionTypes.ExecutionRequest memory req = request;
        ExecutionTypes.ExecutionRequest memory stored = requests[request.requestId];
        if (stored.requestId != bytes32(0)) {
            req = stored;
        }
        if (executed[req.requestId]) {
            revert Errors.AlreadyRegistered();
        }
        if (req.target == address(0)) {
            revert Errors.InvalidAddress();
        }
        if (req.callData.length < 4) {
            revert Errors.InvalidId();
        }
        bytes4 selector = bytes4(req.callData);
        if (!whitelist[req.target][selector]) {
            revert Errors.TargetNotWhitelisted();
        }
        if (req.gasLimit == 0 || req.gasLimit > block.gaslimit) {
            revert Errors.GasLimitExceeded();
        }
        if (locked) {
            revert Errors.Reentrancy();
        }
        locked = true;
        uint256 gasBefore = gasleft();
        (bool success, bytes memory returnData) = req.target.call{value: req.value, gas: req.gasLimit}(req.callData);
        uint256 gasUsed = gasBefore - gasleft();
        locked = false;

        bytes32 returnDataHash = keccak256(returnData);
        executed[req.requestId] = true;

        ExecutionTypes.ExecutionReceipt memory receipt = ExecutionTypes.ExecutionReceipt({
            requestId: req.requestId,
            ruleId: req.ruleId,
            target: req.target,
            success: success,
            returnDataHash: returnDataHash,
            gasUsed: gasUsed,
            executedBy: msg.sender,
            executedAt: block.timestamp
        });
        emit Executed(
            req.requestId,
            req.ruleId,
            req.target,
            success,
            returnDataHash,
            gasUsed,
            msg.sender,
            block.timestamp
        );
        return receipt;
    }
}
