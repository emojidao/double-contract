// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

interface IMarket {
    enum OrderType {
        Public, // 0
        Private, // 1
        Event_Private //2
    }

    enum PaymentType {
        Normal // 0
    }

    struct Lending {
        address lender;
        address nftAddress;
        uint256 nftId;
        uint64 maxEndTime;
        uint64 minDuration;
        uint64 createTime;
        uint64 nonce;
        OrderType orderType;
        PaymentType paymentType;
    }

    struct PaymentNormal {
        address token;
        uint256 pricePerDay;
    }

    event CreateLendOrder(
        address lender,
        address nftAddress,
        uint256 nftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken,
        address renter,
        OrderType orderType
    );
    event CancelLendOrder(address lender, address nftAddress, uint256 nftId);
    event FulfillOrder(
        address renter,
        address lender,
        address nftAddress,
        uint256 nftId,
        uint64 startTime,
        uint64 endTime,
        uint256 pricePerDay,
        uint256 newId,
        address paymentToken
    );
    event Paused(address account);
    event Unpaused(address account);

    function mintAndCreateLendOrder(
        address resolverAddress,
        uint256 oNftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken
    ) external;

    function createLendOrder(
        address nftAddress,
        uint256 nftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken
    ) external;

    function cancelLendOrder(address nftAddress, uint256 nftId) external;

    function getLendOrder(address nftAddress, uint256 nftId)
        external
        view
        returns (Lending memory);

    function getRenterOfPrivateLendOrder(address nftAddress, uint256 nftId)
        external
        view
        returns (address);

    function getPaymentNormal(address nftAddress, uint256 nftId)
        external
        view
        returns (PaymentNormal memory paymentNormal);

    function fulfillOrderNow(
        address nftAddress,
        uint256 nftId,
        uint256 durationId,
        uint64 duration,
        address user
    ) external payable returns (uint256 tid);

    function setFee(uint256 fee) external;

    function getFee() external view returns (uint256);

    function setMarketBeneficiary(address payable beneficiary) external;

    function claimFee(address[] calldata paymentTokens) external;

    function claimRoyalty(address nftAddress, address[] calldata paymentTokens)
        external;

    function isLendOrderValid(address nftAddress, uint256 nftId)
        external
        view
        returns (bool);

    function setPause(bool v) external;
}
