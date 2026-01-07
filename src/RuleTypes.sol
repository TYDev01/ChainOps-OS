// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Shared rule types for ChainOps automation.
library RuleTypes {
    enum RuleCategory {
        THRESHOLD,
        DELTA,
        FREQUENCY
    }

    enum Comparison {
        GT,
        GTE,
        LT,
        LTE,
        EQ,
        NEQ
    }

    struct Rule {
        bytes32 id;
        RuleCategory category;
        Comparison comparison;
        uint256 threshold;
        uint256 timeWindow;
        uint256 frequency;
        bool enabled;
        bytes32 metadataHash;
    }
}
