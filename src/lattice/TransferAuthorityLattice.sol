// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {AuthorityLattice, Clearance} from "src/lattice/AuthorityLattice.sol";

/// @title Transfer Authority Lattice
/// @author jtriley2p
/// @notice The authority lattice but with two-step authority transferrance to mitigate migration
///         mistakes.
/// @notice ⚠️WARNING⚠️ Transferring authority from one account to another is a destructive action,
///         The sender's authority is deleted on initiation and the receiver's authority is
///         overwritten on finalization. The intended functionality of this logic is to migrate
///         accounts without the maximal authority otherwise necessary for authority updates.
abstract contract TransferAuthorityLattice is AuthorityLattice {
    /// @notice Logged on a pending authority update.
    /// @param sender Account which sends the authority.
    /// @param receiver Account which receives the authority.
    /// @param authority The authority to transfer.
    event PendingAuthorityUpdate(address indexed sender, address indexed receiver, uint256 indexed authority);

    /// @notice Pending Sender-Receiver-Authority mapping.
    mapping(address sender => mapping(address receiver => uint256)) public pendingAuthorities;

    /// @notice Initiates an authority transfer.
    /// @dev Pending authority is set and sender's authority is deleted.
    /// @param receiver Account to which the authority is sent.
    function sendAuthority(address receiver) public {
        uint256 authority = authorities[msg.sender];

        pendingAuthorities[msg.sender][receiver] = authority;
        delete authorities[msg.sender];

        emit AuthorityUpdate(msg.sender, msg.sender, Clearance.BOTTOM);
        emit PendingAuthorityUpdate(msg.sender, receiver, authority);
    }

    /// @notice Cancels an authority transfer.
    /// @dev Sender's authority is restored and pending authority is deleted.
    /// @param receiver Account which would have otherwise received authority.
    function cancelSendAuthority(address receiver) public {
        uint256 authority = pendingAuthorities[msg.sender][receiver];

        require(authority != Clearance.BOTTOM);

        authorities[msg.sender] = authority;
        delete pendingAuthorities[msg.sender][receiver];

        emit AuthorityUpdate(msg.sender, msg.sender, authority);
        emit PendingAuthorityUpdate(msg.sender, receiver, Clearance.BOTTOM);
    }

    /// @notice Finalizes an authority transfer.
    /// @dev Receiver's authority is set and pending authority is deleted.
    /// @param sender Account from which the authority was transferred.
    function receiveAuthority(address sender) public {
        address receiver = msg.sender;
        uint256 authority = pendingAuthorities[sender][receiver];

        require(authority != Clearance.BOTTOM);

        authorities[receiver] = authority;
        delete pendingAuthorities[sender][receiver];

        emit AuthorityUpdate(receiver, receiver, authority);
        emit PendingAuthorityUpdate(sender, receiver, Clearance.BOTTOM);
    }

    /// @notice Renounces authority entirely.
    /// @dev Sender's authority is deleted.
    function renounceAuthority() public {
        delete authorities[msg.sender];

        emit AuthorityUpdate(msg.sender, msg.sender, Clearance.BOTTOM);
    }

    /// @notice Revokes an account's pending authority transfer on their behalf.
    /// @dev Caller MUST be authorized to update accounts.
    /// @dev This is to avoid an issue where an account can keep a authority pending to avoid
    ///      revocation.
    /// @param sender Address from which the authority was sent.
    /// @param receiver Address to which the authority was sent.
    function revokePendingAuthority(address sender, address receiver) public {
        require(cleared(msg.sender, Clearance.TOP));

        delete pendingAuthorities[sender][receiver];

        emit PendingAuthorityUpdate(sender, receiver, Clearance.BOTTOM);
    }
}
