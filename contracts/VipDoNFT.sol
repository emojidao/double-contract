// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ComplexDoNFT.sol";
import "./CheckInMgr.sol";
import "./DoubleSVG.sol";

abstract contract VipDoNFT is ComplexDoNFT,CheckInMgr{

    function mintXNft(uint256 oid) public nonReentrant virtual override returns(uint256 tid){
        require(oid2xid[oid] == 0, "already wraped");
        require(onlyApprovedOrOwner(msg.sender,oNftAddress,oid),"only approved or owner");
        address lastOwner = ERC721(oNftAddress).ownerOf(oid);
        ERC721(oNftAddress).safeTransferFrom(lastOwner, address(this), oid);
        tid = mintDoNft(lastOwner,oid,uint64(block.timestamp),type(uint64).max);
        oid2xid[oid] = tid;
    }

    function checkIn(address to,uint256 tokenId,uint256 durationId) public override virtual{
        BaseDoNFT.checkIn(to,tokenId,durationId);
        Duration storage duration = durationMapping[durationId];
        setUser(doNftMapping[tokenId].oid, to,duration.end);
    }

}
