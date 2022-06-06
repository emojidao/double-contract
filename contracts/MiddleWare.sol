// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./market/IMarket.sol";
import "./IComplexDoNFT.sol";

interface IDoNFT is IComplexDoNFT, IERC721Metadata {}

contract MiddleWare {
    struct DoNftMarketInfo {
        uint256 originalNftId;
        uint128 orderPricePerDay;
        uint64 startTime;
        uint64 endTime;
        uint32 orderCreateTime;
        uint32 orderMinDuration;
        uint32 orderMaxEndTime;
        uint32 orderFee; //   ratio = fee / 1e5 , orderFee = 1000 means 1%
        uint8 orderType; // 0: Public, 1: Private, 2: Event_Private
        bool orderIsValid;
        address originalNftAddress;
        address owner;
        address user;
        address orderPrivateRenter;
        address orderPaymentToken;
    }

    function getNftOwnerAndUser(
        address originalNftAddr,
        uint256 orginalNftId,
        address doNftAddr
    ) public view returns (address owner, address user) {
        IBaseDoNFT doNft = IBaseDoNFT(doNftAddr);
        IERC721Metadata oNft = IERC721Metadata(originalNftAddr);

        try oNft.ownerOf(orginalNftId) returns (address ownerAddr) {
            owner = ownerAddr;
        } catch {}

        try doNft.getUser(orginalNftId) returns (address userAddr) {
            user = userAddr;
        } catch {}
    }

    function getNftOwner(address nftAddr, uint256 nftId)
        public
        view
        returns (address owner)
    {
        IERC721Metadata nft = IERC721Metadata(nftAddr);
        try nft.ownerOf(nftId) returns (address ownerAddr) {
            owner = ownerAddr;
        } catch {}
    }

    function getNftOwnerAndTokenURI(address nftAddr, uint256 nftId)
        public
        view
        returns (address owner, string memory uri)
    {
        IERC721Metadata nft = IERC721Metadata(nftAddr);
        try nft.ownerOf(nftId) returns (address ownerAddr) {
            owner = ownerAddr;
        } catch {}

        try nft.tokenURI(nftId) returns (string memory tokenURI) {
            uri = tokenURI;
        } catch {}
    }

    function getDoNftMarketInfo(
        address nftAddr,
        uint256 nftId,
        address marketAddr
    ) public view returns (DoNftMarketInfo memory doNftInfo) {
        IDoNFT doNft = IDoNFT(nftAddr);
        IMarket market = IMarket(marketAddr);

        doNftInfo.originalNftAddress = doNft.getOriginalNftAddress();
        doNftInfo.orderFee =
            uint32(market.getFee()) +
            uint32(doNft.getRoyaltyFee());

        if (doNft.exists(nftId)) {
            (
                uint256 oid,
                ,
                uint64[] memory starts,
                uint64[] memory ends,

            ) = doNft.getDoNftInfo(nftId);

            doNftInfo.owner = doNft.ownerOf(nftId);
            doNftInfo.originalNftId = oid;
            doNftInfo.user = doNft.getUser(oid);
            doNftInfo.startTime = starts[0];
            doNftInfo.endTime = ends[0];
            doNftInfo.orderIsValid = market.isLendOrderValid(nftAddr, nftId);
            if (doNftInfo.orderIsValid) {
                IMarket.Lending memory order = market.getLendOrder(
                    nftAddr,
                    nftId
                );
                IMarket.PaymentNormal memory pNormal = market.getPaymentNormal(
                    nftAddr,
                    nftId
                );
                if (
                    order.orderType == IMarket.OrderType.Private ||
                    order.orderType == IMarket.OrderType.Event_Private
                ) {
                    doNftInfo.orderPrivateRenter = market
                        .getRenterOfPrivateLendOrder(nftAddr, nftId);
                }
                doNftInfo.orderType = uint8(order.orderType);
                doNftInfo.orderMinDuration = uint32(order.minDuration);
                doNftInfo.orderMaxEndTime = uint32(order.maxEndTime);
                doNftInfo.orderCreateTime = uint32(order.createTime);
                doNftInfo.orderPricePerDay = uint128(pNormal.pricePerDay);
                doNftInfo.orderPaymentToken = pNormal.token;
            }
        }
    }

    function batchIsApprovedForAll(address owner, address[] calldata operators, address[] calldata erc721Array) external view returns (bool[] memory results) {
        results = new bool[](erc721Array.length);
        for(uint i = 0; i < erc721Array.length; i++) {
            results[i] = IERC721(erc721Array[i]).isApprovedForAll(owner, operators[i]);
        }
    }

    function batchGetDoNftIdByONftId(address[] calldata doNftAddressArray, uint256[] calldata oNftIdArray) external view returns (uint256[] memory doNftIdArray) {
        require(doNftAddressArray.length == oNftIdArray.length, "invalid input data");
        doNftIdArray = new uint256[](doNftAddressArray.length);
        for(uint i = 0; i < doNftAddressArray.length; i++) {
            doNftIdArray[i] = IDoNFT(doNftAddressArray[i]).getVNftId(oNftIdArray[i]);
        }
    }

}
