// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {AgentManager} from "../src/AgentManager.sol";

contract AgentManagerTest is Test {
    function testConstructorSetsAdmin() public {
        address admin = address(0xA11CE);
        AgentManager manager = new AgentManager(admin);
        assertTrue(manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), admin));
    }

    function testRegisterAgentRequiresRole() public {
        AgentManager manager = new AgentManager(address(this));
        address caller = address(0xBEEF);
        vm.prank(caller);
        vm.expectRevert();
        manager.registerAgent(caller, keccak256("meta"));
    }

    function testRegisterAgentEmitsEvent() public {
        AgentManager manager = new AgentManager(address(this));
        manager.grantRole(manager.AGENT_ADMIN(), address(this));
        bytes32 meta = keccak256("meta");
        vm.expectEmit(true, false, false, true);
        emit AgentManager.AgentRegistered(address(this), meta);
        manager.registerAgent(address(this), meta);
    }

    function testDisableAgentEmitsEvent() public {
        AgentManager manager = new AgentManager(address(this));
        manager.grantRole(manager.AGENT_ADMIN(), address(this));
        manager.registerAgent(address(this), keccak256("meta"));
        vm.expectEmit(true, false, false, false);
        emit AgentManager.AgentDisabled(address(this));
        manager.disableAgent(address(this));
    }

    function testSetScopesUpdatesState() public {
        AgentManager manager = new AgentManager(address(this));
        manager.grantRole(manager.AGENT_ADMIN(), address(this));
        manager.registerAgent(address(this), keccak256("meta"));
        manager.setScopes(address(this), 7);
        AgentManager.Agent memory agent = manager.getAgent(address(this));
        assertEq(agent.scopes, 7);
    }
}
