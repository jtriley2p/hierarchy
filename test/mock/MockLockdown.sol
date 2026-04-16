// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import {Lockdown} from "src/temporal/Lockdown.sol";

contract MockLockdown is Lockdown {
    mapping(address => bool) internal _hasLockdownAuthority;

    constructor(uint64 _lockdownDuration) Lockdown(_lockdownDuration) {}

    function hasLockdownAuthority(address account) public view override returns (bool) {
        return _hasLockdownAuthority[account];
    }

    function _mockSetHasLockdownAuthority(address account, bool hasAuth) public {
        _hasLockdownAuthority[account] = hasAuth;
    }

    function _mockSetLastLockdown(uint64 newLastLockdown) public {
        lastLockdown = newLastLockdown;
    }
}
