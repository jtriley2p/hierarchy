// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {Administrated1967, ADMIN_SLOT, PENDING_ADMIN_SLOT} from "src/singular/Administrated1967.sol";

contract MockAdministrated1967 is Administrated1967 {
    function mockSetAdmin(address newAdmin) public {
        assembly {
            sstore(ADMIN_SLOT, newAdmin)
        }
    }

    function mockSetPendingAdmin(address newPendingAdmin) public {
        assembly {
            sstore(PENDING_ADMIN_SLOT, newPendingAdmin)
        }
    }
}
