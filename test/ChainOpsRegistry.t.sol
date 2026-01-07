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
}
