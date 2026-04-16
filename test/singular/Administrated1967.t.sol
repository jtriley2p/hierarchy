// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {Administrated1967} from "src/singular/Administrated1967.sol";
import {MockAdministrated1967} from "test/mock/MockAdministrated1967.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract AdministratedTest is Test {
    address alice = vm.addr(0x01);
    address bob = vm.addr(0x02);
    address charlie = vm.addr(0x03);

    MockAdministrated1967 administrated;

    function setUp() public {
        administrated = new MockAdministrated1967();
    }

    function testSmokeCheck() public view {
        // basic check in case foundry changes default caller behavior
        address admin = administrated.admin();
        assertNotEq(alice, admin);
        assertNotEq(bob, admin);
        assertNotEq(charlie, admin);
    }

    function testSendAdmin() public {
        administrated.mockSetAdmin(alice);

        vm.expectEmit(true, true, true, true, address(administrated));
        emit Administrated1967.SendAdmin(bob);

        vm.prank(alice);
        administrated.sendAdmin(bob);

        assertEq(bob, administrated.pendingAdmin());
    }

    function testSendAdminResend() public {
        administrated.mockSetAdmin(alice);

        vm.expectEmit(true, true, true, true, address(administrated));
        emit Administrated1967.SendAdmin(bob);

        vm.prank(alice);
        administrated.sendAdmin(bob);

        assertEq(bob, administrated.pendingAdmin());

        vm.expectEmit(true, true, true, true, address(administrated));
        emit Administrated1967.SendAdmin(charlie);

        vm.prank(alice);
        administrated.sendAdmin(charlie);

        assertEq(charlie, administrated.pendingAdmin());
    }

    function testSendAdminNotAdmin() public {
        vm.expectRevert();

        vm.prank(bob);
        administrated.sendAdmin(bob);
    }

    function testFuzzSendAdmin(address admin, address caller, address receiver) public {
        administrated.mockSetAdmin(admin);

        if (admin == caller) {
            vm.expectEmit(true, true, true, true, address(administrated));
            emit Administrated1967.SendAdmin(receiver);
        } else {
            vm.expectRevert();
        }

        vm.prank(caller);
        administrated.sendAdmin(receiver);

        if (admin == caller) {
            assertEq(receiver, administrated.pendingAdmin());
        }
    }

    function receiveAdmin() public {
        administrated.mockSetPendingAdmin(alice);

        vm.expectEmit(true, true, true, true, address(administrated));
        emit Administrated1967.ReceiveAdmin();

        vm.prank(alice);
        administrated.receiveAdmin();

        assertEq(alice, administrated.admin());
        assertEq(address(0x00), administrated.pendingAdmin());
    }

    function testReceiveAdminNotPendingAdmin() public {
        administrated.mockSetPendingAdmin(alice);

        vm.expectRevert();

        vm.prank(bob);
        administrated.receiveAdmin();

        assertEq(alice, administrated.pendingAdmin());
    }

    function testFuzzReceiveAdmin(address pendingAdmin, address caller) public {
        administrated.mockSetPendingAdmin(pendingAdmin);

        if (pendingAdmin == caller) {
            vm.expectEmit(true, true, true, true, address(administrated));
            emit Administrated1967.ReceiveAdmin();
        } else {
            vm.expectRevert();
        }

        vm.prank(caller);
        administrated.receiveAdmin();

        if (pendingAdmin == caller) {
            assertEq(caller, administrated.admin());
            assertEq(address(0x00), administrated.pendingAdmin());
        } else {
            assertEq(pendingAdmin, administrated.pendingAdmin());
        }
    }

    function testEndToEnd(address admin, address nextAdmin, address sendCaller, address receiveCaller) public {
        administrated.mockSetAdmin(admin);

        if (admin == sendCaller) {
            vm.expectEmit(true, true, true, true, address(administrated));
            emit Administrated1967.SendAdmin(nextAdmin);

            vm.prank(sendCaller);
            administrated.sendAdmin(nextAdmin);

            if (nextAdmin == receiveCaller) {
                vm.expectEmit(true, true, true, true, address(administrated));
                emit Administrated1967.ReceiveAdmin();

                vm.prank(receiveCaller);
                administrated.receiveAdmin();

                assertEq(nextAdmin, administrated.admin());
                assertEq(address(0x00), administrated.pendingAdmin());
            } else {
                vm.expectRevert();

                vm.prank(receiveCaller);
                administrated.receiveAdmin();

                assertEq(admin, administrated.admin());
                assertEq(nextAdmin, administrated.pendingAdmin());
            }
        } else {
            vm.expectRevert();

            vm.prank(sendCaller);
            administrated.sendAdmin(nextAdmin);

            assertEq(admin, administrated.admin());
            assertEq(address(0x00), administrated.pendingAdmin());
        }
    }
}
