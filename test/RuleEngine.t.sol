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

    function testRegisterRuleRequiresRole() public {
        RuleEngine engine = new RuleEngine(address(this));
        RuleTypes.Rule memory rule = RuleTypes.Rule({
            id: keccak256("rule"),
            category: RuleTypes.RuleCategory.THRESHOLD,
            comparison: RuleTypes.Comparison.GT,
            threshold: 10,
            timeWindow: 0,
            frequency: 0,
            enabled: true,
            metadataHash: keccak256("meta")
        });
        address caller = address(0xBEEF);
        vm.prank(caller);
        vm.expectRevert();
        engine.registerRule(rule);
    }

    function testRegisterRuleEmitsEvent() public {
        RuleEngine engine = new RuleEngine(address(this));
        engine.grantRole(engine.RULE_ADMIN(), address(this));
        RuleTypes.Rule memory rule = RuleTypes.Rule({
            id: keccak256("rule"),
            category: RuleTypes.RuleCategory.THRESHOLD,
            comparison: RuleTypes.Comparison.GT,
            threshold: 10,
            timeWindow: 0,
            frequency: 0,
            enabled: true,
            metadataHash: keccak256("meta")
        });
        vm.expectEmit(true, false, false, true);
        emit RuleEngine.RuleRegistered(rule.id, rule.category);
        engine.registerRule(rule);
    }
}
