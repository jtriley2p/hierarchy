// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

/// @title Lockdown Contract
/// @author jtriley2p
/// @notice Minimal contract capable of issuing temporary lockdowns.
/// @notice There is also a cooldown equal to the lockdown duration such that the lockdown authority
///         cannot halt actions indefinitely.
abstract contract Lockdown {
    /// @notice Logged when lockdown is initiated.
    event InitiateLockdown();

    /// @notice Last lockdown timestamp.
    uint64 public lastLockdown;

    /// @notice Lockdown duration.
    uint64 public immutable DURATION;

    constructor(uint64 permanentLockdownDuration) {
        DURATION = permanentLockdownDuration;
    }

    /// @dev ABSTRACT:
    /// - MUST return true if account is authorized to initiate lockdown.
    /// - MUST return false if account is not authorized to initiate lockdown.
    function hasLockdownAuthority(address account) public view virtual returns (bool);

    /// @notice Queries if contract is in lockdown.
    /// @return Returns true if contract is in lockdown.
    function inLockdown() public view returns (bool) {
        return lastLockdown != 0 && lastLockdown + DURATION >= block.timestamp;
    }

    function inCooldown() public view returns (bool) {
        return lastLockdown != 0 && lastLockdown + 2 * DURATION >= block.timestamp;
    }

    /// @notice Initiates lockdown.
    /// @dev Throws if there was a lockdown in the last 28 days.
    function initiateLockdown() public {
        require(hasLockdownAuthority(msg.sender));

        require(!inCooldown());

        lastLockdown = uint64(block.timestamp);

        emit InitiateLockdown();
    }
}
