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
}
