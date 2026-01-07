// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {RuleEngine} from "../src/RuleEngine.sol";
import {RuleTypes} from "../src/RuleTypes.sol";

contract RuleEngineTest is Test {
    function testConstructorSetsAdmin() public {
        address admin = address(0xA11CE);
        RuleEngine engine = new RuleEngine(admin);
        assertTrue(engine.hasRole(engine.DEFAULT_ADMIN_ROLE(), admin));
    }
}
