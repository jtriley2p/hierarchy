// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {MockLinearLattice} from "test/mock/MockLinearLattice.sol";
import {Clearance} from "src/lattice/AuthorityLattice.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract LinearLatticeTest is Test {
    address internal admin = vm.addr(0x01);
    address internal bob = vm.addr(0x02);
    address internal charlie = vm.addr(0x03);

    uint256 internal constant AUTHORITY_A = 0x01;
    uint256 internal constant AUTHORITY_B = 0x02;

    MockLinearLattice manager;

    function setUp() public {
        vm.prank(admin);

        manager = new MockLinearLattice();
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

    function testAuthorities() public {
        vm.prank(admin);
        manager.updateAuthority(bob, AUTHORITY_B);

        assertTrue(manager.cleared(bob, AUTHORITY_A));
    }

    function testFuzzAuthorities(address account, uint256 authority0, uint256 authority1) public {
        vm.prank(admin);
        manager.updateAuthority(account, authority0);

        assertEq(manager.cleared(account, authority1), authority0 >= authority1);
    }
}
