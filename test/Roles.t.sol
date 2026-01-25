// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {Roles} from "../src/Roles.sol";

contract RolesHarness is Roles {
    constructor(address admin) Roles(admin) {}

    function initialize(address admin) external {
        _initialize(admin);
    }
}

contract RolesTest is Test {
    function testConstructorRejectsZeroAdmin() public {
        vm.expectRevert();
        new RolesHarness(address(0));
    }

    function testGrantRoleRequiresAdmin() public {
        RolesHarness roles = new RolesHarness(address(this));
        bytes32 execRole = roles.EXECUTOR();
        vm.startPrank(address(0xBEEF));
        vm.expectRevert();
        roles.grantRole(execRole, address(0xCAFE));
        vm.stopPrank();
    }

    function testGrantRoleUpdatesState() public {
        RolesHarness roles = new RolesHarness(address(this));
        roles.grantRole(roles.EXECUTOR(), address(0xCAFE));
        assertTrue(roles.hasRole(roles.EXECUTOR(), address(0xCAFE)));
    }

    function testRevokeRoleUpdatesState() public {
        RolesHarness roles = new RolesHarness(address(this));
        roles.grantRole(roles.EXECUTOR(), address(0xCAFE));
        roles.revokeRole(roles.EXECUTOR(), address(0xCAFE));
        assertFalse(roles.hasRole(roles.EXECUTOR(), address(0xCAFE)));
    }

    function testRevokeRoleRequiresAdmin() public {
        RolesHarness roles = new RolesHarness(address(this));
        bytes32 execRole = roles.EXECUTOR();
        roles.grantRole(execRole, address(0xCAFE));
        vm.startPrank(address(0xBEEF));
        vm.expectRevert();
        roles.revokeRole(execRole, address(0xCAFE));
        vm.stopPrank();
    }
}
