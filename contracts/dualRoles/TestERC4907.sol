// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC4907.sol";

contract TestERC4907 is ERC4907 {
    constructor() ERC4907("TestERC4907", "TestERC4907") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
