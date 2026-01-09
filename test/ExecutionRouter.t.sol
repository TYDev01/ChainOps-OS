// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {ExecutionRouter} from "../src/ExecutionRouter.sol";
import {ExecutionTypes} from "../src/ExecutionTypes.sol";

contract DummyTarget {
    function ping() external pure returns (uint256) {
        return 42;
    }
}

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

    function testExecuteEmitsReceipt() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        DummyTarget target = new DummyTarget();
        bytes4 selector = DummyTarget.ping.selector;
        router.whitelistTarget(address(target), selector, true);

        ExecutionTypes.ExecutionRequest memory req = ExecutionTypes.ExecutionRequest({
            requestId: keccak256("req"),
            ruleId: keccak256("rule"),
            target: address(target),
            value: 0,
            gasLimit: 100000,
            callData: abi.encodeWithSelector(selector),
            requestedBy: address(this),
            requestedAt: block.timestamp
        });

        vm.expectEmit(true, true, true, false);
        emit ExecutionRouter.Executed(req.requestId, req.ruleId, req.target, true);
        ExecutionTypes.ExecutionReceipt memory receipt = router.execute(req);
        assertEq(receipt.requestId, req.requestId);
        assertTrue(receipt.success);
    }

    function testExecuteRevertsWhenNotWhitelisted() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        DummyTarget target = new DummyTarget();
        ExecutionTypes.ExecutionRequest memory req = ExecutionTypes.ExecutionRequest({
            requestId: keccak256("req"),
            ruleId: keccak256("rule"),
            target: address(target),
            value: 0,
            gasLimit: 100000,
            callData: abi.encodeWithSelector(DummyTarget.ping.selector),
            requestedBy: address(this),
            requestedAt: block.timestamp
        });
        vm.expectRevert();
        router.execute(req);
    }

    function testExecuteRevertsWhenGasLimitExceeded() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        DummyTarget target = new DummyTarget();
        bytes4 selector = DummyTarget.ping.selector;
        router.whitelistTarget(address(target), selector, true);
        ExecutionTypes.ExecutionRequest memory req = ExecutionTypes.ExecutionRequest({
            requestId: keccak256("req"),
            ruleId: keccak256("rule"),
            target: address(target),
            value: 0,
            gasLimit: block.gaslimit + 1,
            callData: abi.encodeWithSelector(selector),
            requestedBy: address(this),
            requestedAt: block.timestamp
        });
        vm.expectRevert();
        router.execute(req);
    }
}
