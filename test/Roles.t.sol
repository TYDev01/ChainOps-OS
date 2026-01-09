// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {Roles} from "../src/Roles.sol";

contract RolesHarness is Roles {
    constructor(address admin) Roles(admin) {}
}

contract RolesTest is Test {
    function testGrantRoleRequiresAdmin() public {
        RolesHarness roles = new RolesHarness(address(this));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        roles.grantRole(roles.EXECUTOR(), address(0xCAFE));
    }
}
