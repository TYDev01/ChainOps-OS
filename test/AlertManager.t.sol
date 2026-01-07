// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {AlertManager} from "../src/AlertManager.sol";

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
}
