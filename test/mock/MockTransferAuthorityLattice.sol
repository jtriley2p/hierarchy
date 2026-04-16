// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {TransferAuthorityLattice} from "src/lattice/TransferAuthorityLattice.sol";

// minimal mock to just do an equality check
//
// makes isolating logic on this contract simpler.
contract MockTransferAuthorityLattice is TransferAuthorityLattice {
    function cleared(address account, uint256 expectedAuthority) public view override returns (bool) {
        return authorities[account] == expectedAuthority;
    }
}
