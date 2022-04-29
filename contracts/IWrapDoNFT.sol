// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IWrapDoNFT {
    event Redeem(uint256 oid, uint256 tokenId);

    function couldRedeem(uint256 tokenId, uint256[] calldata durationIds)
        external
        view
        returns (bool);

    function redeem(uint256 tokenId, uint256[] calldata durationIds) external;
}
