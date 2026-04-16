// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {Timelock} from "src/temporal/Timelock.sol";

contract MockTimelock is Timelock {
    mapping(address => bool) internal _hasTimelockUpdateAuthority;

    constructor(uint64 minTimelock, uint64 maxTimelock) Timelock(minTimelock, maxTimelock) {}

    function hasTimelockUpdateAuthority(address account) public view override returns (bool) {
        return _hasTimelockUpdateAuthority[account];
    }

    function mockSetHasTimelockUpdateAuthority(address account, bool hasAuthority) public {
        _hasTimelockUpdateAuthority[account] = hasAuthority;
    }

    function mockSetTimelock(uint64 newTimelock) public {
        timelock = newTimelock;
    }

    function mockSetNextTimelock(uint64 newNextTimelock) public {
        nextTimelock = newNextTimelock;
    }

    function mockSetTimelockUpdateReadyAt(uint64 newTimelockUpdateReadyAt) public {
        timelockUpdateReadyAt = newTimelockUpdateReadyAt;
    }
}
