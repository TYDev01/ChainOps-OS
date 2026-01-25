// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {ExecutionRouter} from "../src/ExecutionRouter.sol";
import {ExecutionTypes} from "../src/ExecutionTypes.sol";

contract ExecutionAgentManagerMock {
    bool public allowed;

    function setAllowed(bool value) external {
        allowed = value;
    }

    function hasScope(address, uint8) external view returns (bool) {
        return allowed;
    }
}

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
        emit ExecutionRouter.Executed(
            req.requestId,
            req.ruleId,
            req.target,
            true,
            keccak256(abi.encode(uint256(42))),
            0,
            address(this),
            block.timestamp
        );
        router.requestExecution(req);
        ExecutionTypes.ExecutionReceipt memory receipt = router.execute(req);
        assertEq(receipt.requestId, req.requestId);
        assertTrue(receipt.success);
        assertGt(receipt.gasUsed, 0);
        assertTrue(router.isExecuted(req.requestId));
    }

    function testExecuteRequiresScopeWhenAgentManagerSet() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        DummyTarget target = new DummyTarget();
        bytes4 selector = DummyTarget.ping.selector;
        router.whitelistTarget(address(target), selector, true);
        ExecutionAgentManagerMock agentManager = new ExecutionAgentManagerMock();
        router.setAgentManager(address(agentManager));

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
        router.requestExecution(req);

        agentManager.setAllowed(false);
        vm.expectRevert();
        router.execute(req);

        agentManager.setAllowed(true);
        ExecutionTypes.ExecutionReceipt memory receipt = router.execute(req);
        assertTrue(receipt.success);
    }

    function testSetAgentManagerRequiresAdmin() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        router.setAgentManager(address(0xCAFE));
    }

    function testExecuteUsesStoredRequest() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        DummyTarget target = new DummyTarget();
        bytes4 selector = DummyTarget.ping.selector;
        router.whitelistTarget(address(target), selector, true);

        ExecutionTypes.ExecutionRequest memory storedReq = ExecutionTypes.ExecutionRequest({
            requestId: keccak256("stored"),
            ruleId: keccak256("rule"),
            target: address(target),
            value: 0,
            gasLimit: 100000,
            callData: abi.encodeWithSelector(selector),
            requestedBy: address(this),
            requestedAt: block.timestamp
        });
        router.requestExecution(storedReq);

        ExecutionTypes.ExecutionRequest memory execReq = ExecutionTypes.ExecutionRequest({
            requestId: storedReq.requestId,
            ruleId: keccak256("other"),
            target: address(0xBEEF),
            value: 1,
            gasLimit: 1,
            callData: hex"1234",
            requestedBy: address(0xBEEF),
            requestedAt: block.timestamp
        });

        ExecutionTypes.ExecutionReceipt memory receipt = router.execute(execReq);
        assertEq(receipt.requestId, storedReq.requestId);
        assertEq(receipt.target, address(target));
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
        router.requestExecution(req);
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
        router.requestExecution(req);
        vm.expectRevert();
        router.execute(req);
    }

    function testExecuteRevertsWhenCallDataTooShort() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        DummyTarget target = new DummyTarget();
        ExecutionTypes.ExecutionRequest memory req = ExecutionTypes.ExecutionRequest({
            requestId: keccak256("req"),
            ruleId: keccak256("rule"),
            target: address(target),
            value: 0,
            gasLimit: 100000,
            callData: hex"1234",
            requestedBy: address(this),
            requestedAt: block.timestamp
        });
        router.requestExecution(req);
        vm.expectRevert();
        router.execute(req);
    }

    function testExecuteRevertsWhenTargetZero() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        ExecutionTypes.ExecutionRequest memory req = ExecutionTypes.ExecutionRequest({
            requestId: keccak256("req"),
            ruleId: keccak256("rule"),
            target: address(0),
            value: 0,
            gasLimit: 100000,
            callData: abi.encodeWithSelector(DummyTarget.ping.selector),
            requestedBy: address(this),
            requestedAt: block.timestamp
        });
        router.requestExecution(req);
        vm.expectRevert();
        router.execute(req);
    }

    function testExecuteRevertsWhenRequestMissing() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        ExecutionTypes.ExecutionRequest memory req = ExecutionTypes.ExecutionRequest({
            requestId: keccak256("missing"),
            ruleId: keccak256("rule"),
            target: address(0xCAFE),
            value: 0,
            gasLimit: 100000,
            callData: abi.encodeWithSelector(DummyTarget.ping.selector),
            requestedBy: address(this),
            requestedAt: block.timestamp
        });
        vm.expectRevert();
        router.execute(req);
    }

    function testRequestExecutionEmitsEvent() public {
        ExecutionRouter router = new ExecutionRouter(address(this));
        router.grantRole(router.EXECUTOR(), address(this));
        ExecutionTypes.ExecutionRequest memory req = ExecutionTypes.ExecutionRequest({
            requestId: keccak256("req"),
            ruleId: keccak256("rule"),
            target: address(0xCAFE),
            value: 0,
            gasLimit: 100000,
            callData: abi.encodeWithSelector(DummyTarget.ping.selector),
            requestedBy: address(this),
            requestedAt: block.timestamp
        });
        vm.expectEmit(true, true, true, false);
        emit ExecutionRouter.ExecutionRequested(req.requestId, req.ruleId, req.target);
        router.requestExecution(req);
        ExecutionTypes.ExecutionRequest memory stored = router.getRequest(req.requestId);
        assertEq(stored.requestedBy, address(this));
        assertEq(stored.requestedAt, block.timestamp);
    }
}
