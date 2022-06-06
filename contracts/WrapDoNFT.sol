// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IWrapDoNFT.sol";
import "./BaseDoNFT.sol";

abstract contract WrapDoNFT is BaseDoNFT, IWrapDoNFT {
    using EnumerableSet for EnumerableSet.UintSet;


    function couldRedeem(uint256 tokenId, uint256[] calldata durationIds)
        public
        view
        virtual
        returns (bool)
    {
        require(isVNft(tokenId), "not vNFT");
        DoNftInfo storage info = doNftMapping[tokenId];
        Duration storage duration = durationMapping[durationIds[0]];
        if (duration.start > block.timestamp) {
            return false;
        }
        uint64 lastEndTime = duration.end;
        for (uint256 index = 1; index < durationIds.length; index++) {
            require(
                info.durationList.contains(durationIds[index]),
                string(abi.encodePacked("not contails", durationIds[index]))
            );
            duration = durationMapping[durationIds[index]];
            if (lastEndTime + 1 == duration.start) {
                lastEndTime = duration.end;
            }
        }
        return lastEndTime == type(uint64).max;
    }

    function redeem(uint256 tokenId, uint256[] calldata durationIds)
        public
        virtual
    {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        require(couldRedeem(tokenId, durationIds), "cannot redeem");
        DoNftInfo storage info = doNftMapping[tokenId];
        ERC721(oNftAddress).safeTransferFrom(
            address(this),
            ownerOf(tokenId),
            info.oid
        );
        _burnVNft(tokenId);
        emit Redeem(info.oid, tokenId);
    }
}
