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

    function testEvaluateEmitsEvent() public {
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
        engine.registerRule(rule);
        bytes32 payload = keccak256("payload");
        vm.expectEmit(true, true, false, true);
        emit RuleEngine.RuleEvaluated(rule.id, address(this), true, payload);
        bool passed = engine.evaluate(rule.id, 11, payload);
        assertTrue(passed);
    }

    function testEvaluateRevertsWhenDisabled() public {
        RuleEngine engine = new RuleEngine(address(this));
        engine.grantRole(engine.RULE_ADMIN(), address(this));
        RuleTypes.Rule memory rule = RuleTypes.Rule({
            id: keccak256("rule"),
            category: RuleTypes.RuleCategory.THRESHOLD,
            comparison: RuleTypes.Comparison.GT,
            threshold: 10,
            timeWindow: 0,
            frequency: 0,
            enabled: false,
            metadataHash: keccak256("meta")
        });
        engine.registerRule(rule);
        vm.expectRevert();
        engine.evaluate(rule.id, 11, keccak256("payload"));
    }

    function testSetRuleStatusUpdatesState() public {
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
        engine.registerRule(rule);
        vm.expectEmit(true, false, false, true);
        emit RuleEngine.RuleStatusUpdated(rule.id, false);
        engine.setRuleStatus(rule.id, false);
        RuleTypes.Rule memory stored = engine.getRule(rule.id);
        assertFalse(stored.enabled);
    }

    function testSetRuleStatusRequiresRole() public {
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
        engine.registerRule(rule);
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        engine.setRuleStatus(rule.id, false);
    }

    function testDeltaRuleEvaluatesOnSecondValue() public {
        RuleEngine engine = new RuleEngine(address(this));
        engine.grantRole(engine.RULE_ADMIN(), address(this));
        RuleTypes.Rule memory rule = RuleTypes.Rule({
            id: keccak256("delta"),
            category: RuleTypes.RuleCategory.DELTA,
            comparison: RuleTypes.Comparison.GT,
            threshold: 5,
            timeWindow: 0,
            frequency: 0,
            enabled: true,
            metadataHash: keccak256("meta")
        });
        engine.registerRule(rule);
        bool first = engine.evaluate(rule.id, 10, keccak256("payload1"));
        assertFalse(first);
        bool second = engine.evaluate(rule.id, 20, keccak256("payload2"));
        assertTrue(second);
    }

    function testFrequencyRuleCountsWithinWindow() public {
        RuleEngine engine = new RuleEngine(address(this));
        engine.grantRole(engine.RULE_ADMIN(), address(this));
        RuleTypes.Rule memory rule = RuleTypes.Rule({
            id: keccak256("freq"),
            category: RuleTypes.RuleCategory.FREQUENCY,
            comparison: RuleTypes.Comparison.GTE,
            threshold: 0,
            timeWindow: 100,
            frequency: 2,
            enabled: true,
            metadataHash: keccak256("meta")
        });
        engine.registerRule(rule);
        bool first = engine.evaluate(rule.id, 1, keccak256("payload1"));
        assertFalse(first);
        bool second = engine.evaluate(rule.id, 1, keccak256("payload2"));
        assertTrue(second);
    }

    function testRegisterFrequencyRuleRejectsZeroParams() public {
        RuleEngine engine = new RuleEngine(address(this));
        engine.grantRole(engine.RULE_ADMIN(), address(this));
        RuleTypes.Rule memory rule = RuleTypes.Rule({
            id: keccak256("freq"),
            category: RuleTypes.RuleCategory.FREQUENCY,
            comparison: RuleTypes.Comparison.GTE,
            threshold: 0,
            timeWindow: 0,
            frequency: 0,
            enabled: true,
            metadataHash: keccak256("meta")
        });
        vm.expectRevert();
        engine.registerRule(rule);
    }
}
