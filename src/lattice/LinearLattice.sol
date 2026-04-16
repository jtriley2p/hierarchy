// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {AuthorityLattice} from "src/lattice/AuthorityLattice.sol";

/// @title Linear Lattice
/// @author jtriley2p
/// @notice Defines authority clearance by a "greater than or equal to" check such that any
///         authority clearance implies clearance of subordinate authority.
abstract contract LinearLattice is AuthorityLattice {
    /// @notice Returns true if the account has authority clearance.
    /// @dev Checks if account's authority is greater than or equal to the expected.
    /// @param account Account for which to check clearance.
    /// @param expectedAuthority Minimum authority required for clearance.
    function cleared(address account, uint256 expectedAuthority) public view override returns (bool) {
        return expectedAuthority <= authorities[account];
    }
}
