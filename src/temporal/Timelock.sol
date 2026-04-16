// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

/// @title Timelock
/// @author jtriley2p
/// @notice Abstract timelock contract to force actions to queue in a timelock before execution.
abstract contract Timelock {
    /// @notice Logged when timelock update is queued.
    /// @param newTimelock New timelock after update.
    event QueueTimelockUpdate(address caller, uint64 newTimelock);

    /// @notice Looged when timelock update is finalized.
    event FinalizeTimelockUpdate();

    /// @notice Current timelock.
    uint64 public timelock;

    /// @notice Next timelock to be set. MUST be zero if there is no timelock update queue.
    uint64 public nextTimelock;

    /// @notice Timestamp at which the current queued timelock update, if any, is ready to be
    ///         finalized.
    uint64 public timelockUpdateReadyAt;

    uint64 public immutable MIN_TIMELOCK;
    uint64 public immutable MAX_TIMELOCK;

    constructor(uint64 minTimelock, uint64 maxTimelock) {
        require(minTimelock <= maxTimelock);

        timelock = MIN_TIMELOCK;
        MIN_TIMELOCK = minTimelock;
        MAX_TIMELOCK = maxTimelock;
    }

    /// @dev Returns true if the account is authorized to update the timelock.
    function hasTimelockUpdateAuthority(address account) public view virtual returns (bool);

    /// @notice Queues a timelock update.
    /// @param newTimelock New timelock after update finalized.
    function queueTimelockUpdate(uint64 newTimelock) public {
        require(hasTimelockUpdateAuthority(msg.sender));
        require(MIN_TIMELOCK <= newTimelock && newTimelock <= MAX_TIMELOCK);

        nextTimelock = newTimelock;
        timelockUpdateReadyAt = uint64(timelock + block.timestamp);

        emit QueueTimelockUpdate(msg.sender, newTimelock);
    }

    /// @notice Finalizes a timelock update.
    /// @dev Throws if timelock update is not ready.
    function finalizeTimelockUpdate() public {
        require(block.timestamp >= timelockUpdateReadyAt);
        require(timelockUpdateReadyAt != 0);

        timelock = nextTimelock;
        delete nextTimelock;
        delete timelockUpdateReadyAt;

        emit FinalizeTimelockUpdate();
    }
}
