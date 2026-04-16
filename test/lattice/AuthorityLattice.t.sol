// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {MockAuthorityLattice} from "test/mock/MockAuthorityLattice.sol";
import {AuthorityLattice, Clearance} from "src/lattice/AuthorityLattice.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract AuthorityLatticeTest is Test {
    address internal admin = vm.addr(0x01);
    address internal bob = vm.addr(0x02);
    address internal charlie = vm.addr(0x03);

    uint256 internal constant AUTHORITY_A = 0x01;

    MockAuthorityLattice manager;

    function setUp() public {
        vm.prank(admin);

        manager = new MockAuthorityLattice();
    }

    function testUpdateAuthority() public {
        vm.expectEmit(true, true, true, true, address(manager));
        emit AuthorityLattice.AuthorityUpdate(admin, bob, AUTHORITY_A);

        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);

        assertEq(manager.authorities(bob), AUTHORITY_A);
    }

    function testUpdateAuthorityNotAuthorized() public {
        vm.expectRevert();

        vm.prank(bob);
        manager.updateAuthority(bob, AUTHORITY_A);
    }

    function testFuzzUpdateAuthority(
        bool coinToss,
        address updater,
        address caller,
        address receiver,
        uint256 authority
    ) public {
        // transfer authority to updater
        // this avoids issues of updater-admin address collisions in fuzz logic
        if (admin != updater) {
            vm.prank(admin);
            manager.updateAuthority(updater, Clearance.TOP);

            vm.prank(admin);
            manager.updateAuthority(admin, Clearance.BOTTOM);
        }

        // makes `caller == updater` 50-50 to cover more authorized cases.
        if (coinToss) {
            caller = updater;
        }

        uint256 authorityBefore = manager.authorities(receiver);

        if (caller == updater) {
            vm.expectEmit(true, true, true, true, address(manager));
            emit AuthorityLattice.AuthorityUpdate(caller, receiver, authority);
        } else {
            vm.expectRevert();
        }

        vm.prank(caller);
        manager.updateAuthority(receiver, authority);

        if (caller == updater) {
            assertEq(manager.authorities(receiver), authority);
        } else {
            assertEq(manager.authorities(receiver), authorityBefore);
        }
    }
}
