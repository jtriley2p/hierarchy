// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
bytes32 constant PENDING_ADMIN_SLOT = 0x8b2bdfe1250d0e6b0c2034608336566041b2cfc76c628c23f12b93744b938494;

/// @title Administrated ERC1967 Contract
/// @author jtriley2p
/// @notice Simple, single authorized address abstract contract for ERC1967. Transition requires two
///         steps; current admin sends authorization to new admin, new admin accepts authorization.
///         This requires the new be capable of calling this contract before transition, preventing
///         bricking.
/// @dev DOES NOT include other ERC1967 storage slots (ie implementation and beacon).
abstract contract Administrated1967 {
    /// @notice Logged when admin authority is sent.
    /// @param newAdmin New admin address.
    event SendAdmin(address indexed newAdmin);

    /// @notice Logged when admin authority is received.
    event ReceiveAdmin();

    constructor() {
        assembly {
            sstore(ADMIN_SLOT, caller())
        }
    }

    /// @notice Returns admin address.
    function admin() public view returns (address adm) {
        assembly {
            adm := sload(ADMIN_SLOT)
        }
    }

    /// @notice Returns pending admin address.
    /// @dev Address is non-zero only between sending and receiving admin.
    function pendingAdmin() public view returns (address pending) {
        assembly {
            pending := sload(PENDING_ADMIN_SLOT)
        }
    }

    /// @notice Sends admin authority.
    /// @param newAdmin New admin address.
    function sendAdmin(address newAdmin) public {
        require(msg.sender == admin());

        assembly {
            sstore(PENDING_ADMIN_SLOT, newAdmin)
        }

        emit SendAdmin(newAdmin);
    }

    /// @notice Receives admin authority.
    function receiveAdmin() public {
        require(msg.sender == pendingAdmin());

        assembly {
            sstore(ADMIN_SLOT, caller())

            sstore(PENDING_ADMIN_SLOT, 0x00)
        }

        emit ReceiveAdmin();
    }
}
