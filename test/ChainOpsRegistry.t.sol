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
}
