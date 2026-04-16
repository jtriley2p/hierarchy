// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {AuthorityLattice} from "src/lattice/AuthorityLattice.sol";

/// @title Role Power Set Lattice
/// @author jtriley2p
/// @notice Defines authority clearance by set inclusion, in practice a "bitwise inclusion" check
///         such that authority clearance does not necessarily imply clearance of other authority.
///         Additionally, while multiple "sets" of authority may exist, there exist authority set
///         unions such that inclusion in, aka clearance of, the union of two authority sets implies
///         clearance of those two authority sets.
abstract contract RolePowerSetLattice is AuthorityLattice {
    /// @notice Returns true if the account has authority clearance.
    /// @dev Checks if account's authority contains at least all of the expected bits.
    /// @param account Account for which to check clearance.
    /// @param expectedAuthority Minimum authority required for clearance.
    function cleared(address account, uint256 expectedAuthority) public view override returns (bool) {
        return authorities[account] & expectedAuthority == expectedAuthority;
    }
}
