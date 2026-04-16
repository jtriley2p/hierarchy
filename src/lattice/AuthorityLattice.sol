// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

library Clearance {
    /// @dev The minimal authority (Meet)
    uint256 constant BOTTOM = 0;

    /// @dev The maximal authority (Join)
    uint256 constant TOP = type(uint256).max;
}

/// @title Authority Lattice
/// @author jtriley2p
/// @notice Authority management contract which enables generic lattice-like structures of
///         hierarchies. Accounts have authority ranging from "TOP" to "BOTTOM" where accounts with
///         TOP authority are administrators and accounts with BOTTOM authority are the default
///         state with no special clearance.
abstract contract AuthorityLattice {
    /// @notice Logged on Authority Updates.
    /// @param caller Account which triggered the update.
    /// @param account Account for which authority is updated.
    /// @param authority The written authority.
    event AuthorityUpdate(address indexed caller, address indexed account, uint256 indexed authority);

    /// @notice Account-Authority mapping.
    mapping(address account => uint256) public authorities;

    /// @notice Deployer is set to `Clearance.TOP` to enable configuration.
    constructor() {
        authorities[msg.sender] = Clearance.TOP;
    }

    /// @notice Returns true if the account is cleared to the authority.
    /// @param account Account for which to check clearance.
    /// @param expectedAuthority Minimum authority required for clearance.
    function cleared(address account, uint256 expectedAuthority) public view virtual returns (bool);

    /// @notice Updates an account's authority on their behalf.
    /// @dev Caller MUST be maximally cleared.
    /// @param account Account for which authority is updated.
    /// @param authority New authority after update.
    function updateAuthority(address account, uint256 authority) public {
        require(cleared(msg.sender, Clearance.TOP));

        authorities[account] = authority;

        emit AuthorityUpdate(msg.sender, account, authority);
    }
}
