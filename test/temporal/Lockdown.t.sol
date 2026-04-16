// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {Lockdown} from "src/temporal/Lockdown.sol";
import {MockLockdown} from "test/mock/MockLockdown.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract LockdownTest is Test {
    address alice = vm.addr(0x01);
    address bob = vm.addr(0x02);
    uint64 exampleLockdownDuration = 1;

    MockLockdown lockdown;

    function setUp() public {
        lockdown = new MockLockdown(exampleLockdownDuration);
    }

    function testLockdownDuration() public view {
        assertEq(exampleLockdownDuration, lockdown.DURATION());
    }

    function testInLockdownLt() public {
        lockdown._mockSetLastLockdown(1);
        vm.warp(3);

        assertFalse(lockdown.inLockdown());
    }

    function testInLockdownEq() public {
        lockdown._mockSetLastLockdown(1);
        vm.warp(2);

        assertTrue(lockdown.inLockdown());
    }

    function testInLockdownGt() public {
        lockdown._mockSetLastLockdown(2);
        vm.warp(2);

        assertTrue(lockdown.inLockdown());
    }

    function testInitiateLockdown() public {
        lockdown._mockSetHasLockdownAuthority(alice, true);

        vm.warp(3);

        vm.expectEmit(true, true, true, true, address(lockdown));
        emit Lockdown.InitiateLockdown();

        vm.prank(alice);
        lockdown.initiateLockdown();

        assertEq(lockdown.lastLockdown(), block.timestamp);
        assertTrue(lockdown.inLockdown());

        vm.warp(4);

        assertEq(lockdown.lastLockdown(), block.timestamp - 1);
        assertTrue(lockdown.inLockdown());

        vm.warp(5);

        assertEq(lockdown.lastLockdown(), block.timestamp - 2);
        assertFalse(lockdown.inLockdown());
    }

    function testInitiateLockdownNoAuthority() public {
        lockdown._mockSetHasLockdownAuthority(alice, true);

        vm.expectRevert();

        vm.prank(bob);
        lockdown.initiateLockdown();
    }

    function testInitiateLockdownCooldown() public {
        lockdown._mockSetHasLockdownAuthority(alice, true);

        vm.warp(3);

        vm.expectEmit(true, true, true, true, address(lockdown));
        emit Lockdown.InitiateLockdown();

        vm.prank(alice);
        lockdown.initiateLockdown();

        assertEq(lockdown.lastLockdown(), block.timestamp);
        assertTrue(lockdown.inLockdown());

        vm.warp(5);

        vm.expectRevert();

        vm.prank(alice);
        lockdown.initiateLockdown();
    }
}
