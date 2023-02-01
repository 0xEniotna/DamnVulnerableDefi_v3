// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/src/utils/SafeTransferLib.sol";

import "./ClimberTimelock.sol";
import {WITHDRAWAL_LIMIT, WAITING_PERIOD} from "./ClimberConstants.sol";
import {CallerNotSweeper, InvalidWithdrawalAmount, InvalidWithdrawalTime} from "./ClimberErrors.sol";

contract ClimberUpgrade is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Must define the same variables to maintain storage layout
    // Note that constant variables do not take storage slots (they are replaced at runtime)
    uint256 _lastWithdrawalTimestamp;
    address _sweeper;

    function drain(address _token) external {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    // Required by UUPSUpgradeable
    function _authorizeUpgrade(address) internal override {}
}
