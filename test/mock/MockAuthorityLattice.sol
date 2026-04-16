// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {AuthorityLattice} from "src/lattice/LinearLattice.sol";

// minimal mock to just do an equality check
//
// makes isolating logic on this contract simpler.
contract MockAuthorityLattice is AuthorityLattice {
    function cleared(address account, uint256 expectedAuthority) public view override returns (bool) {
        return authorities[account] == expectedAuthority;
    }
}
