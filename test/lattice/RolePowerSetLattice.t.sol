// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {MockRolePowerSetLattice} from "test/mock/MockRolePowerSetLattice.sol";
import {Clearance} from "src/lattice/AuthorityLattice.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract RolePowerSetLatticeTest is Test {
    address internal admin = vm.addr(0x01);
    address internal bob = vm.addr(0x02);
    address internal charlie = vm.addr(0x03);
    address internal dani = vm.addr(0x04);

    uint256 internal constant AUTHORITY_A = 1 << 0;
    uint256 internal constant AUTHORITY_B = 1 << 1;

    uint256 internal constant AUTHORITY_AB = AUTHORITY_A | AUTHORITY_B;

    MockRolePowerSetLattice manager;

    function setUp() public {
        vm.prank(admin);

        manager = new MockRolePowerSetLattice();
    }

    function testBottom() public {
        vm.prank(admin);
        manager.updateAuthority(bob, Clearance.BOTTOM);

        assertFalse(manager.cleared(bob, AUTHORITY_A));
        assertFalse(manager.cleared(bob, Clearance.TOP));
    }

    function testFuzzBottom(address account, uint256 authority) public {
        authority = bound(authority, 1, type(uint256).max);

        vm.prank(admin);
        manager.updateAuthority(account, Clearance.BOTTOM);

        assertFalse(manager.cleared(account, authority));
    }

    function testTop() public {
        vm.prank(admin);
        manager.updateAuthority(bob, Clearance.TOP);

        assertTrue(manager.cleared(bob, AUTHORITY_A));
        assertTrue(manager.cleared(bob, Clearance.BOTTOM));
    }

    function testFuzzTop(address account, uint256 authority) public {
        authority = bound(authority, 1, type(uint256).max);

        vm.prank(admin);
        manager.updateAuthority(account, Clearance.TOP);

        assertTrue(manager.cleared(account, authority));
    }

    function testIncomparableAuthorities() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);
        vm.prank(admin);
        manager.updateAuthority(charlie, AUTHORITY_B);

        assertFalse(manager.cleared(bob, AUTHORITY_B));
        assertFalse(manager.cleared(charlie, AUTHORITY_A));
    }

    function testComposableAuthorities() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_A);

        vm.prank(admin);
        manager.updateAuthority(charlie, AUTHORITY_B);

        vm.prank(admin);
        manager.updateAuthority(dani, AUTHORITY_AB);

        assertFalse(manager.cleared(bob, AUTHORITY_AB));
        assertFalse(manager.cleared(charlie, AUTHORITY_AB));

        assertTrue(manager.cleared(dani, Clearance.BOTTOM));
        assertTrue(manager.cleared(dani, AUTHORITY_A));
        assertTrue(manager.cleared(dani, AUTHORITY_B));
        assertFalse(manager.cleared(dani, Clearance.TOP));
    }

    function testFuzzAuthoritiess(address account, uint256 authority0, uint256 authority1) public {
        vm.prank(admin);
        manager.updateAuthority(account, authority0);

        assertEq(manager.cleared(account, authority1), authority0 & authority1 == authority1);
    }
}
