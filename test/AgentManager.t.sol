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
}
