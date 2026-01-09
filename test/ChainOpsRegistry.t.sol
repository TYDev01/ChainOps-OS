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
        bytes32 id = keccak256("module");
        bytes32 meta = keccak256("meta");
        vm.expectEmit(true, true, false, true);
        emit ChainOpsRegistry.AnalyticsModuleRegistered(id, address(this), meta);
        registry.registerAnalyticsModule(id, address(this), meta);
    }

    function testRegisterAnalyticsModuleRejectsDuplicate() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        bytes32 id = keccak256("module");
        registry.registerAnalyticsModule(id, address(this), keccak256("meta"));
        vm.expectRevert();
        registry.registerAnalyticsModule(id, address(this), keccak256("meta2"));
    }

    function testRegisterAutomationRuleEmitsEvent() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.RULE_ADMIN(), address(this));
        bytes32 id = keccak256("rule");
        bytes32 meta = keccak256("meta");
        vm.expectEmit(true, true, false, true);
        emit ChainOpsRegistry.AutomationRuleRegistered(id, address(this), meta);
        registry.registerAutomationRule(id, address(this), meta);
    }

    function testRegisterAgentEmitsEvent() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        registry.grantRole(registry.AGENT_ADMIN(), address(this));
        bytes32 id = keccak256("agent");
        bytes32 meta = keccak256("meta");
        vm.expectEmit(true, true, false, true);
        emit ChainOpsRegistry.AgentRegistered(id, address(this), meta);
        registry.registerAgent(id, address(this), meta);
    }

    function testSetAnalyticsModuleStatusRequiresRole() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        bytes32 id = keccak256("module");
        registry.grantRole(registry.REGISTRY_ADMIN(), address(this));
        registry.registerAnalyticsModule(id, address(this), keccak256("meta"));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.setAnalyticsModuleStatus(id, false);
    }

    function testSetAutomationRuleStatusRequiresRole() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        bytes32 id = keccak256("rule");
        registry.grantRole(registry.RULE_ADMIN(), address(this));
        registry.registerAutomationRule(id, address(this), keccak256("meta"));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.setAutomationRuleStatus(id, false);
    }

    function testSetAgentStatusRequiresRole() public {
        ChainOpsRegistry registry = new ChainOpsRegistry(address(this));
        bytes32 id = keccak256("agent");
        registry.grantRole(registry.AGENT_ADMIN(), address(this));
        registry.registerAgent(id, address(this), keccak256("meta"));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.setAgentStatus(id, false);
    }
}
