// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {ChainOpsRegistry} from "../src/ChainOpsRegistry.sol";

contract ChainOpsRegistryTest is Test {
    function testConstructorSetsAdmin() public {
        address admin = address(0xA11CE);
        ChainOpsRegistry registry = new ChainOpsRegistry(admin);
        assertTrue(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), admin));
    }

    function testRegisterAnalyticsModuleRequiresRole() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        address caller = address(0xBEEF);
        bytes32 id = keccak256("module");
        vm.prank(caller);
        vm.expectRevert();
        registry.registerAnalyticsModule(id, caller, keccak256("meta"));
    }

    function testRegisterAnalyticsModuleEmitsEvent() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_ANALYTICS(), address(this), meta);
        vm.expectEmit(true, true, false, true);
        emit ChainOpsRegistry.AnalyticsModuleRegistered(id, address(this), meta);
        registry.registerAnalyticsModule(id, address(this), meta);
    }

    function testRegisterAnalyticsModuleRejectsDuplicate() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_ANALYTICS(), address(this), meta);
        registry.registerAnalyticsModule(id, address(this), meta);
        vm.expectRevert();
        registry.registerAnalyticsModule(id, address(this), keccak256("meta2"));
    }

    function testRegisterAutomationRuleEmitsEvent() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.RULE_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_RULE(), address(this), meta);
        vm.expectEmit(true, true, false, true);
        emit ChainOpsRegistry.AutomationRuleRegistered(id, address(this), meta);
        registry.registerAutomationRule(id, address(this), meta);
    }

    function testRegisterAgentEmitsEvent() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.AGENT_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_AGENT(), address(this), meta);
        vm.expectEmit(true, true, false, true);
        emit ChainOpsRegistry.AgentRegistered(id, address(this), meta);
        registry.registerAgent(id, address(this), meta);
    }

    function testSetAnalyticsModuleStatusRequiresRole() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_ANALYTICS(), address(this), meta);
        registry.registerAnalyticsModule(id, address(this), meta);
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.setAnalyticsModuleStatus(id, false);
    }

    function testSetAutomationRuleStatusRequiresRole() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.RULE_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_RULE(), address(this), meta);
        registry.registerAutomationRule(id, address(this), meta);
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.setAutomationRuleStatus(id, false);
    }

    function testSetAgentStatusRequiresRole() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.AGENT_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_AGENT(), address(this), meta);
        registry.registerAgent(id, address(this), meta);
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.setAgentStatus(id, false);
    }

    function testSetAnalyticsModuleStatusUpdatesState() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_ANALYTICS(), address(this), meta);
        registry.registerAnalyticsModule(id, address(this), meta);
        vm.expectEmit(true, false, false, true);
        emit ChainOpsRegistry.AnalyticsModuleStatusUpdated(id, false);
        registry.setAnalyticsModuleStatus(id, false);
        ChainOpsRegistry.Entry memory entry = registry.getAnalyticsModule(id);
        assertFalse(entry.enabled);
    }

    function testSetAutomationRuleStatusUpdatesState() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.RULE_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_RULE(), address(this), meta);
        registry.registerAutomationRule(id, address(this), meta);
        vm.expectEmit(true, false, false, true);
        emit ChainOpsRegistry.AutomationRuleStatusUpdated(id, false);
        registry.setAutomationRuleStatus(id, false);
        ChainOpsRegistry.Entry memory entry = registry.getAutomationRule(id);
        assertFalse(entry.enabled);
    }

    function testSetAgentStatusUpdatesState() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.AGENT_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_AGENT(), address(this), meta);
        registry.registerAgent(id, address(this), meta);
        vm.expectEmit(true, false, false, true);
        emit ChainOpsRegistry.AgentStatusUpdated(id, false);
        registry.setAgentStatus(id, false);
        ChainOpsRegistry.Entry memory entry = registry.getAgent(id);
        assertFalse(entry.enabled);
    }

    function testComputeIdMatchesHash() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        bytes32 kind = registry.KIND_ANALYTICS();
        bytes32 meta = keccak256("meta");
        bytes32 expected = keccak256(abi.encodePacked(kind, address(this), meta));
        bytes32 computed = registry.computeId(kind, address(this), meta);
        assertEq(computed, expected);
    }

    function testRegisterAnalyticsModuleRejectsWrongId() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 wrongId = keccak256("wrong");
        vm.expectRevert();
        registry.registerAnalyticsModule(wrongId, address(this), meta);
    }

    function testTransferAnalyticsModuleOwnership() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_ANALYTICS(), address(this), meta);
        registry.registerAnalyticsModule(id, address(this), meta);
        vm.expectEmit(true, true, true, false);
        emit ChainOpsRegistry.AnalyticsModuleOwnershipTransferred(id, address(this), address(0xBEEF));
        registry.transferAnalyticsModuleOwnership(id, address(0xBEEF));
        ChainOpsRegistry.Entry memory entry = registry.getAnalyticsModule(id);
        assertEq(entry.owner, address(0xBEEF));
    }

    function testTransferAnalyticsModuleOwnershipRejectsUnauthorized() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_ANALYTICS(), address(this), meta);
        registry.registerAnalyticsModule(id, address(this), meta);
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.transferAnalyticsModuleOwnership(id, address(0xCAFE));
    }

    function testTransferAutomationRuleOwnership() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.RULE_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_RULE(), address(this), meta);
        registry.registerAutomationRule(id, address(this), meta);
        vm.expectEmit(true, true, true, false);
        emit ChainOpsRegistry.AutomationRuleOwnershipTransferred(id, address(this), address(0xBEEF));
        registry.transferAutomationRuleOwnership(id, address(0xBEEF));
        ChainOpsRegistry.Entry memory entry = registry.getAutomationRule(id);
        assertEq(entry.owner, address(0xBEEF));
    }

    function testTransferAutomationRuleOwnershipRejectsUnauthorized() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.RULE_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_RULE(), address(this), meta);
        registry.registerAutomationRule(id, address(this), meta);
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.transferAutomationRuleOwnership(id, address(0xCAFE));
    }

    function testTransferAgentOwnership() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.AGENT_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_AGENT(), address(this), meta);
        registry.registerAgent(id, address(this), meta);
        vm.expectEmit(true, true, true, false);
        emit ChainOpsRegistry.AgentOwnershipTransferred(id, address(this), address(0xBEEF));
        registry.transferAgentOwnership(id, address(0xBEEF));
        ChainOpsRegistry.Entry memory entry = registry.getAgent(id);
        assertEq(entry.owner, address(0xBEEF));
    }

    function testTransferAgentOwnershipRejectsUnauthorized() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.AGENT_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        bytes32 id = registry.computeId(registry.KIND_AGENT(), address(this), meta);
        registry.registerAgent(id, address(this), meta);
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.transferAgentOwnership(id, address(0xCAFE));
    }
}
