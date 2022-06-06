// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../VipDoNFT.sol";
import "./ENS.sol";
import "./BaseRegistrar.sol";

contract ENSDoNFT is VipDoNFT {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    ENS public ens;
    mapping(uint256 => uint64) nameExpires;

    function initializeENS(
        string memory name_,
        string memory symbol_,
        address nftAddress_,
        address market_,
        address owner_,
        address admin_,
        address royaltyAdmin_,
        address ens_
    ) public virtual initializer {
        super.initialize(
            name_,
            symbol_,
            nftAddress_,
            market_,
            owner_,
            admin_,
            royaltyAdmin_
        );
        ens = ENS(ens_);
    }

    function mintVNft(uint256 oid)
        public
        virtual
        override
        nonReentrant
        returns (uint256 tid)
    {
        require(oid2vid[oid] == 0, "already wraped");
        require(
            onlyApprovedOrOwner(msg.sender, oNftAddress, oid),
            "only approved or owner"
        );

        if (oid2vid[oid] != 0) {
            (, , uint64 dEnd) = getDurationByIndex(oid2vid[oid], 0);
            if (block.timestamp > dEnd) {
                _burnVNft(oid2vid[oid]);
            }
        }

        address lastOwner = ERC721(oNftAddress).ownerOf(oid);
        ERC721(oNftAddress).safeTransferFrom(lastOwner, address(this), oid);
        uint64 _end = SafeCast.toUint64(
            BaseRegistrar(oNftAddress).nameExpires(oid)
        );
        tid = mintDoNft(lastOwner, oid, uint64(block.timestamp), _end);
        oid2vid[oid] = tid;
        nameExpires[oid] = _end;
    }

    function getUser(uint256 originalNftId)
        public
        view
        virtual
        override
        returns (address)
    {
        bytes32 baseNode = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

        bytes32 label = bytes32(originalNftId);
        bytes32 subnode = keccak256(abi.encodePacked(baseNode, label));
        return ens.owner(subnode);
    }

    function setUser(
        uint256 oid,
        address to,
        uint64 expiredAt
    ) internal virtual override {
        super.setUser(oid, to, expiredAt);
        BaseRegistrar(oNftAddress).reclaim(oid, to);
    }

    function couldRedeem(uint256 tokenId, uint256[] calldata durationIds)
        public
        view
        override
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
        return lastEndTime == nameExpires[info.oid];
    }
}
