// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDoubleSVG {
    function genTokenURI(
        uint256 tokenId,
        string memory name,
        string memory type_value,
        uint64 start_time,
        uint64 end_time
    ) external view returns (string memory);
}
