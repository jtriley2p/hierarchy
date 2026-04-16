// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {Timelock} from "src/temporal/Timelock.sol";
import {MockTimelock} from "test/mock/MockTimelock.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract TimelockTest is Test {
    address alice = vm.addr(0x01);
    address bob = vm.addr(0x02);
    uint64 exampleTimelock = 1;

    uint64 constant MIN_TIMELOCK = 0;
    uint64 constant MAX_TIMELOCK = type(uint64).max;

    MockTimelock timelock;

    function setUp() public {
        timelock = new MockTimelock(MIN_TIMELOCK, MAX_TIMELOCK);
    }

    function testQueueTimelockUpdate() public {
        timelock.mockSetHasTimelockUpdateAuthority(alice, true);

        vm.expectEmit(true, true, true, true, address(timelock));
        emit Timelock.QueueTimelockUpdate(alice, exampleTimelock);

        vm.prank(alice);
        timelock.queueTimelockUpdate(exampleTimelock);

        assertEq(timelock.timelock(), 0);
        assertEq(timelock.nextTimelock(), exampleTimelock);
        assertEq(timelock.timelockUpdateReadyAt(), block.timestamp + 0);
    }

    function testQueueTimelockUpdateNotAuthorized() public {
        vm.expectRevert();

        vm.prank(alice);
        timelock.queueTimelockUpdate(exampleTimelock);
    }

    function testFuzzQueueTimelockUpdate(address authorized, address caller, uint64 nextTimelock) public {
        nextTimelock = uint64(bound(nextTimelock, 0, type(uint64).max - 1));

        timelock.mockSetHasTimelockUpdateAuthority(authorized, true);

        if (authorized == caller) {
            vm.expectEmit(true, true, true, true, address(timelock));
            emit Timelock.QueueTimelockUpdate(caller, nextTimelock);
        } else {
            vm.expectRevert();
        }

        vm.prank(caller);
        timelock.queueTimelockUpdate(nextTimelock);

        if (authorized == caller) {
            assertEq(timelock.timelock(), 0);
            assertEq(timelock.nextTimelock(), nextTimelock);
            assertEq(timelock.timelockUpdateReadyAt(), block.timestamp + 0);
        }
    }

    function testFinalizeTimelockUpdate() public {
        timelock.mockSetNextTimelock(exampleTimelock);
        timelock.mockSetTimelockUpdateReadyAt(uint64(block.timestamp));

        vm.expectEmit(true, true, true, true, address(timelock));
        emit Timelock.FinalizeTimelockUpdate();

        timelock.finalizeTimelockUpdate();

        assertEq(timelock.timelock(), exampleTimelock);
        assertEq(timelock.nextTimelock(), 0);
        assertEq(timelock.timelockUpdateReadyAt(), 0);
    }

    function testFinalizeTimelockUpdateTimelockNotReady() public {
        timelock.mockSetTimelockUpdateReadyAt(uint64(block.timestamp + 1));

        vm.expectRevert();

        timelock.finalizeTimelockUpdate();
    }

    function testFinalizeTimelockUpdateTimelockNotSet() public {
        vm.expectRevert();

        timelock.finalizeTimelockUpdate();
    }

    function testFuzzFinalizeTimelockUpdate(uint64 currentTimestamp, uint64 currentTimelock, uint64 nextTimelock)
        public
    {
        currentTimelock = uint64(bound(currentTimelock, 0, type(uint64).max - currentTimestamp));

        timelock.mockSetNextTimelock(nextTimelock);
        timelock.mockSetTimelockUpdateReadyAt(uint64(block.timestamp + currentTimelock));

        bool timelockValid = currentTimestamp >= currentTimelock + block.timestamp;

        if (timelockValid) {
            vm.expectEmit(true, true, true, true, address(timelock));
            emit Timelock.FinalizeTimelockUpdate();
        } else {
            vm.expectRevert();
        }

        vm.warp(currentTimestamp);

        timelock.finalizeTimelockUpdate();

        if (timelockValid) {
            assertEq(timelock.timelock(), nextTimelock);
            assertEq(timelock.nextTimelock(), 0);
            assertEq(timelock.timelockUpdateReadyAt(), 0);
        }
    }
}
