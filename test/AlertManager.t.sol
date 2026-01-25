// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {AlertManager} from "../src/AlertManager.sol";

contract AlertAgentManagerMock {
    bool public allowed;

    function setAllowed(bool value) external {
        allowed = value;
    }

    function hasScope(address, uint8) external view returns (bool) {
        return allowed;
    }
}

contract AlertManagerTest is Test {
    function testConstructorSetsAdmin() public {
        address admin = address(0xA11CE);
        AlertManager manager = new AlertManager(admin);
        assertTrue(manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), admin));
    }

    function testRegisterAlertRequiresRole() public {
        AlertManager manager = new AlertManager(address(this));
        bytes32 alertId = keccak256("alert");
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        manager.registerAlert(alertId, keccak256("channel"), keccak256("meta"));
    }

    function testRegisterAlertEmitsEvent() public {
        AlertManager manager = new AlertManager(address(this));
        manager.grantRole(manager.REGISTRY_ADMIN(), address(this));
        bytes32 alertId = keccak256("alert");
        bytes32 channel = keccak256("channel");
        bytes32 meta = keccak256("meta");
        vm.expectEmit(true, true, false, true);
        emit AlertManager.AlertRegistered(alertId, channel, meta);
        manager.registerAlert(alertId, channel, meta);
    }

    function testEmitAlertEmitsEvent() public {
        AlertManager manager = new AlertManager(address(this));
        manager.grantRole(manager.REGISTRY_ADMIN(), address(this));
        manager.grantRole(manager.RULE_ADMIN(), address(this));
        bytes32 alertId = keccak256("alert");
        bytes32 channel = keccak256("channel");
        manager.registerAlert(alertId, channel, keccak256("meta"));
        bytes32 payload = keccak256("payload");
        bytes32 ruleId = keccak256("rule");
        vm.expectEmit(true, true, false, true);
        emit AlertManager.AlertTriggered(ruleId, address(this), payload, channel, block.timestamp);
        manager.emitAlert(ruleId, payload, alertId);
    }

    function testEmitAlertRevertsWhenUnregistered() public {
        AlertManager manager = new AlertManager(address(this));
        manager.grantRole(manager.RULE_ADMIN(), address(this));
        vm.expectRevert();
        manager.emitAlert(keccak256("rule"), keccak256("payload"), keccak256("missing"));
    }

    function testEmitAlertRequiresScopeWhenAgentManagerSet() public {
        AlertManager manager = new AlertManager(address(this));
        manager.grantRole(manager.REGISTRY_ADMIN(), address(this));
        manager.grantRole(manager.RULE_ADMIN(), address(this));
        AlertAgentManagerMock agentManager = new AlertAgentManagerMock();
        manager.setAgentManager(address(agentManager));
        bytes32 alertId = keccak256("alert");
        manager.registerAlert(alertId, keccak256("channel"), keccak256("meta"));
        agentManager.setAllowed(false);
        vm.expectRevert();
        manager.emitAlert(keccak256("rule"), keccak256("payload"), alertId);
        agentManager.setAllowed(true);
        manager.emitAlert(keccak256("rule"), keccak256("payload2"), alertId);
    }

    function testSetAgentManagerRequiresAdmin() public {
        AlertManager manager = new AlertManager(address(this));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        manager.setAgentManager(address(0xCAFE));
    }
}
