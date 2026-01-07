// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {ExecutionRouter} from "../src/ExecutionRouter.sol";
import {ExecutionTypes} from "../src/ExecutionTypes.sol";

contract ExecutionRouterTest is Test {
    function testConstructorSetsAdmin() public {
        address admin = address(0xA11CE);
        ExecutionRouter router = new ExecutionRouter(admin);
        assertTrue(router.hasRole(router.DEFAULT_ADMIN_ROLE(), admin));
    }

    function testWhitelistRequiresRole() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        router.whitelistTarget(address(0xCAFE), bytes4(keccak256("ping()")), true);
    }

    function testWhitelistEmitsEvent() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        address target = address(0xCAFE);
        bytes4 selector = bytes4(keccak256("ping()"));
        vm.expectEmit(true, true, false, true);
        emit ExecutionRouter.TargetWhitelisted(target, selector, true);
        router.whitelistTarget(target, selector, true);
    }
}
