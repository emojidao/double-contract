// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBaseDoNFT.sol";
import "./royalty/IRoyalty.sol";

interface IComplexDoNFT is IBaseDoNFT, IRoyalty {
    function initialize(
        string memory name_,
        string memory symbol_,
        address nftAddress_,
        address market_,
        address owner_,
        address admin_,
        address royaltyAdmin_
    ) external;
}
