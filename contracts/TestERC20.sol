// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("FT", "FT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
