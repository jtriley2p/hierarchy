// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {MockTransferAuthorityLattice} from "test/mock/MockTransferAuthorityLattice.sol";
import {TransferAuthorityLattice} from "src/lattice/TransferAuthorityLattice.sol";
import {AuthorityLattice, Clearance} from "src/lattice/AuthorityLattice.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract TransferAuthorityLatticeTest is Test {
    address internal admin = vm.addr(0x01);
    address internal bob = vm.addr(0x02);
    address internal charlie = vm.addr(0x03);

    uint256 internal constant AUTHORITY_A = 0x01;

    MockTransferAuthorityLattice manager;

    function setUp() public {
        vm.prank(admin);

        manager = new MockTransferAuthorityLattice();
    }

    function testSendAuthority() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);

        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(bob, bob, Clearance.BOTTOM);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TransferAuthorityLattice.PendingAuthorityUpdate(bob, charlie, AUTHORITY_A);

        vm.prank(bob);
        manager.sendAuthority(charlie);

        assertEq(manager.authorities(bob), Clearance.BOTTOM);
        assertEq(manager.authorities(charlie), Clearance.BOTTOM);
        assertEq(manager.pendingAuthorities(bob, charlie), AUTHORITY_A);
    }

    function testFuzzSendAuthority(address sender, address receiver, uint256 role) public {
        vm.assume(sender != receiver);

        vm.prank(admin);
        manager.updateAuthority(sender, role);

        uint256 receiverAuthorityBefore = manager.authorities(receiver);

        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(sender, sender, Clearance.BOTTOM);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TransferAuthorityLattice.PendingAuthorityUpdate(sender, receiver, role);

        vm.prank(sender);
        manager.sendAuthority(receiver);

        assertEq(manager.authorities(sender), Clearance.BOTTOM);
        assertEq(manager.authorities(receiver), receiverAuthorityBefore);
        assertEq(manager.pendingAuthorities(sender, receiver), role);
    }

    function testCancelSendAuthority() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);

        vm.prank(bob);
        manager.sendAuthority(charlie);

        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(bob, bob, AUTHORITY_A);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TransferAuthorityLattice.PendingAuthorityUpdate(bob, charlie, Clearance.BOTTOM);

        vm.prank(bob);
        manager.cancelSendAuthority(charlie);

        assertEq(manager.authorities(bob), AUTHORITY_A);
        assertEq(manager.authorities(charlie), Clearance.BOTTOM);
        assertEq(manager.pendingAuthorities(bob, charlie), Clearance.BOTTOM);
    }

    function testFuzzCancelSendAuthority(address sender, address receiver, uint256 authority) public {
        vm.assume(sender != receiver);

        authority = bound(authority, 1, Clearance.TOP);

        vm.prank(admin);
        manager.updateAuthority(sender, authority);

        vm.prank(sender);
        manager.sendAuthority(receiver);

        uint256 authorityBefore = manager.authorities(receiver);

        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(sender, sender, authority);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TransferAuthorityLattice.PendingAuthorityUpdate(sender, receiver, Clearance.BOTTOM);

        vm.prank(sender);
        manager.cancelSendAuthority(receiver);

        assertEq(manager.authorities(sender), authority);
        assertEq(manager.authorities(receiver), authorityBefore);
        assertEq(manager.pendingAuthorities(sender, receiver), Clearance.BOTTOM);
    }

    function testCancelSendAuthorityDoesNotExist() public {
        vm.expectRevert();

        vm.prank(bob);
        manager.cancelSendAuthority(charlie);
    }

    function testFuzzCancelSendAuthorityDoesNotExist(address sender, address receiver) public {
        vm.expectRevert();

        vm.prank(sender);
        manager.cancelSendAuthority(receiver);
    }

    function testReceiveAuthority() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);

        vm.prank(bob);
        manager.sendAuthority(charlie);

        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(charlie, charlie, AUTHORITY_A);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TransferAuthorityLattice.PendingAuthorityUpdate(bob, charlie, Clearance.BOTTOM);

        vm.prank(charlie);
        manager.receiveAuthority(bob);

        assertEq(manager.authorities(bob), Clearance.BOTTOM);
        assertEq(manager.authorities(charlie), AUTHORITY_A);
        assertEq(manager.pendingAuthorities(bob, charlie), Clearance.BOTTOM);
    }

    function testFuzzReceiveAuthority(address sender, address receiver, uint256 authority) public {
        vm.assume(sender != receiver);

        vm.assume(sender != receiver);

        authority = bound(authority, 1, Clearance.TOP);

        vm.prank(admin);
        manager.updateAuthority(sender, authority);

        vm.prank(sender);
        manager.sendAuthority(receiver);

        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(receiver, receiver, authority);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TransferAuthorityLattice.PendingAuthorityUpdate(sender, receiver, Clearance.BOTTOM);

        vm.prank(receiver);
        manager.receiveAuthority(sender);

        assertEq(manager.authorities(sender), Clearance.BOTTOM);
        assertEq(manager.authorities(receiver), authority);
        assertEq(manager.pendingAuthorities(sender, receiver), Clearance.BOTTOM);
    }

    function testReceiveAuthorityDoesNotExist() public {
        vm.expectRevert();

        vm.prank(charlie);
        manager.receiveAuthority(bob);
    }

    function testFuzzReceiveAuthorityDoesNotExist(address sender, address receiver) public {
        vm.expectRevert();

        vm.prank(receiver);
        manager.receiveAuthority(sender);
    }

    function testRenounceAuthority() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);

        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(bob, bob, Clearance.BOTTOM);

        vm.prank(bob);
        manager.renounceAuthority();

        assertEq(manager.authorities(bob), Clearance.BOTTOM);
    }

    function testFuzzRenounceAuthority(address account, uint256 authority) public {
        vm.prank(admin);
        manager.updateAuthority(account, authority);

        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(bob, bob, Clearance.BOTTOM);

        vm.prank(bob);
        manager.renounceAuthority();

        assertEq(manager.authorities(bob), Clearance.BOTTOM);
    }

    function testRevokePendingAuthority() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);

        vm.prank(bob);
        manager.sendAuthority(charlie);

        vm.expectEmit(true, true, true, true, address(manager));
        emit TransferAuthorityLattice.PendingAuthorityUpdate(bob, charlie, Clearance.BOTTOM);

        vm.prank(admin);
        manager.revokePendingAuthority(bob, charlie);

        assertEq(manager.authorities(bob), Clearance.BOTTOM);
        assertEq(manager.authorities(charlie), Clearance.BOTTOM);
        assertEq(manager.pendingAuthorities(bob, charlie), Clearance.BOTTOM);
    }

    function testRevokePendingAuthorityNotAdmin() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);

        vm.prank(bob);
        manager.sendAuthority(charlie);

        vm.expectRevert();

        vm.prank(bob);
        manager.revokePendingAuthority(bob, charlie);

        assertEq(manager.pendingAuthorities(bob, charlie), AUTHORITY_A);
    }

    function testFuzzRevokePendingAuthority(
        bool coinToss,
        address updater,
        address caller,
        address sender,
        address receiver,
        uint256 authority
    ) public {
        // makes it 50/50
        if (coinToss) {
            caller = updater;
        }

        vm.assume(caller != sender);
        vm.assume(sender != receiver);

        if (admin != updater) {
            vm.prank(admin);
            manager.updateAuthority(updater, Clearance.TOP);
            vm.prank(admin);
            manager.updateAuthority(admin, Clearance.BOTTOM);
        }

        vm.prank(updater);
        manager.updateAuthority(sender, authority);

        vm.prank(sender);
        manager.sendAuthority(receiver);

        if (caller == updater) {
            vm.expectEmit(true, true, true, true, address(manager));
            emit TransferAuthorityLattice.PendingAuthorityUpdate(sender, receiver, Clearance.BOTTOM);
        } else {
            vm.expectRevert();
        }

        vm.prank(caller);
        manager.revokePendingAuthority(sender, receiver);

        if (caller == updater) {
            assertEq(manager.pendingAuthorities(sender, receiver), Clearance.BOTTOM);
        } else {
            assertEq(manager.pendingAuthorities(sender, receiver), authority);
        }
    }

    // function testFuzzRevokePendingRole(
    //     bool coinToss,
    //     address updater,
    //     address caller,
    //     address sender,
    //     address receiver,
    //     uint256 role
    // ) public {
    //     // revoke admin status, set updater status
    //     // this avoids issues of updater-admin collisions
    //     manager.__mockSetRole(admin, Role.BOTTOM);
    //     manager.__mockSetRole(updater, Role.TOP);

    //     manager.__mockSetPendingRole(sender, receiver, role);

    //     // makes `caller == updater` 50-50 to cover more authorized cases.
    //     if (coinToss) {
    //         caller = updater;
    //     }

    //     if (caller == updater) {
    //         vm.expectEmit(true, true, true, true, address(manager));
    //         emit PowerSetRoles.PendingRoleUpdate(sender, receiver, Role.BOTTOM);
    //     } else {
    //         vm.expectRevert();
    //     }

    //     vm.prank(caller);
    //     manager.revokePendingRole(sender, receiver);

    //     if (caller == updater) {
    //         assertEq(manager.pendingRoles(sender, receiver), Role.BOTTOM);
    //     } else {
    //         assertEq(manager.pendingRoles(sender, receiver), role);
    //     }
    // }

    function testSendRole() public {}

    function testSendRoleDoesNotHaveRole() public {}
}
