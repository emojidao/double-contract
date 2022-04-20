// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./market/IMarket.sol";
import "./IComplexDoNFT.sol";

interface IDoNFT is IComplexDoNFT, IERC721Metadata {}

contract MiddleWare {
    struct DoNftMarketInfo {
        uint256 originalNftId; // 0
        uint256 orderPricePerDay; // 1
        uint64 startTime; // 2
        uint64 endTime; // 3
        uint64 orderCreateTime; // 4
        uint64 orderMinDuration; // 5
        uint64 orderMaxEndTime; // 6
        uint64 orderFee; // 7 ,  ratio = fee / 1e5 , orderFee = 1000 means 1%
        address originalNftAddress; // 8
        address owner; // 9
        address user; // 10
        address renter; //11
        address orderPaymentToken; // 12
        bool orderIsValid; // 13
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
            uint64(market.getFee()) +
            uint64(doNft.getRoyaltyFee());

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
                if (order.orderType == IMarket.OrderType.Private) {
                    doNftInfo.renter = market.getRenterOfPrivateLendOrder(
                        nftAddr,
                        nftId
                    );
                }
                doNftInfo.orderMinDuration = order.minDuration;
                doNftInfo.orderMaxEndTime = order.maxEndTime;
                doNftInfo.orderCreateTime = order.createTime;
                doNftInfo.orderPricePerDay = pNormal.pricePerDay;
                doNftInfo.orderPaymentToken = pNormal.token;
            }
        }
    }
}
