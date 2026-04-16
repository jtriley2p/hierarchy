// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {Administrated} from "src/singular/Administrated.sol";

contract MockAdministrated is Administrated {
    function mockSetAdmin(address newAdmin) public {
        admin = newAdmin;
    }

    function mockSetPendingAdmin(address newPendingAdmin) public {
        pendingAdmin = newPendingAdmin;
    }
}
