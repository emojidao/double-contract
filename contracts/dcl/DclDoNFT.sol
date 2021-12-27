// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../WrapDoNFT.sol";
import "../BaseDoNFT.sol";
import "./IDCL.sol";

contract DclDoNFT is WrapDoNFT{
    using EnumerableSet for EnumerableSet.UintSet;
    string private _dclURI;
    constructor(address address_,string memory name_, string memory symbol_) {
        super.init(address_, name_, symbol_);
    }
    
    function checkIn(address to,uint256 tokenId,uint256 durationId) public override virtual{
        BaseDoNFT.checkIn(to,tokenId,durationId);
        DoNftInfo storage info = doNftMapping[tokenId];
        IDCL(oNftAddress).setUpdateOperator(info.oid, to);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _dclURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(_dclURI, tokenId));
    }

}
