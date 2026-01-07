// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Execution request/receipt types for the router.
library ExecutionTypes {
    struct ExecutionRequest {
        bytes32 requestId;
        bytes32 ruleId;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes callData;
        address requestedBy;
        uint256 requestedAt;
    }

    struct ExecutionReceipt {
        bytes32 requestId;
        bytes32 ruleId;
        address target;
        bool success;
        bytes32 returnDataHash;
        uint256 gasUsed;
        address executedBy;
        uint256 executedAt;
    }
}
