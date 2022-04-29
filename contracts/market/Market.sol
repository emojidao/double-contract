// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IMarket.sol";
import "../OwnableContract.sol";
import "../IComplexDoNFT.sol";
import "../dualRoles/wrap/IWrapNFT.sol";

contract Market is OwnableContract, ReentrancyGuardUpgradeable, IMarket {
    uint64 private constant E5 = 1e5;
    mapping(address => mapping(uint256 => Lending)) internal lendingMap;
    mapping(address => mapping(uint256 => address)) internal privateOrderMap;
    mapping(address => mapping(uint256 => PaymentNormal))
        internal paymentNormalMap;
    mapping(address => mapping(address => uint256)) internal royaltyMap;
    mapping(address => uint256) public balanceOfFee;
    address payable public beneficiary;
    uint256 private fee;
    uint64 public maxIndate;
    bool public isPausing;
    bool public supportERC20;

    function initialize(address owner_, address admin_) public initializer {
        __ReentrancyGuard_init();
        initOwnableContract(owner_, admin_);
        maxIndate = 365 days;
        fee = 2500;
    }

    function onlyApprovedOrOwner(
        address spender,
        address nftAddress,
        uint256 nftId
    ) internal view {
        address _owner = ERC721(nftAddress).ownerOf(nftId);
        require(
            spender == _owner ||
                ERC721(nftAddress).getApproved(nftId) == spender ||
                ERC721(nftAddress).isApprovedForAll(_owner, spender),
            "only approved or owner"
        );
    }

    modifier whenNotPaused() {
        require(!isPausing, "is pausing");
        _;
    }

    function mintAndCreateLendOrder(
        address doNftAddress,
        uint256 oNftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken
    ) public nonReentrant {
        uint256 nftId = _mintV(doNftAddress, oNftId, maxEndTime);
        createLendOrder(
            doNftAddress,
            nftId,
            maxEndTime,
            minDuration,
            pricePerDay,
            paymentToken
        );
    }

    function mintAndCreatePrivateLendOrder(
        address doNftAddress,
        uint256 oNftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken,
        address renter,
        OrderType orderType
    ) public nonReentrant {
        uint256 nftId = _mintV(doNftAddress, oNftId, maxEndTime);
        createPrivateLendOrder(
            doNftAddress,
            nftId,
            maxEndTime,
            minDuration,
            pricePerDay,
            paymentToken,
            renter,
            orderType
        );
    }

    function _mintV(
        address doNftAddress,
        uint256 oNftId,
        uint64 maxEndTime
    ) internal returns (uint256 nftId) {
        address oNftAddress = IComplexDoNFT(doNftAddress)
            .getOriginalNftAddress();
        if (
            IERC165(oNftAddress).supportsInterface(type(IWrapNFT).interfaceId)
        ) {
            address gameNFTAddress = IWrapNFT(oNftAddress).originalAddress();
            bool isStaked = ERC721(gameNFTAddress).ownerOf(oNftId) ==
                oNftAddress;
            if (isStaked) {
                onlyApprovedOrOwner(msg.sender, oNftAddress, oNftId);
            } else {
                onlyApprovedOrOwner(msg.sender, gameNFTAddress, oNftId);
            }
        } else {
            onlyApprovedOrOwner(msg.sender, oNftAddress, oNftId);
        }
        require(maxEndTime > block.timestamp, "invalid maxEndTime");
        nftId = IComplexDoNFT(doNftAddress).mintVNft(oNftId);
    }

    function createLendOrder(
        address nftAddress,
        uint256 nftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken
    ) public whenNotPaused {
        delete privateOrderMap[nftAddress][nftId];
        paymentNormalMap[nftAddress][nftId] = PaymentNormal(
            paymentToken,
            pricePerDay
        );
        _createLendOrder(
            nftAddress,
            nftId,
            maxEndTime,
            minDuration,
            pricePerDay,
            paymentToken,
            OrderType.Public,
            PaymentType.Normal,
            address(0)
        );
    }

    function createPrivateLendOrder(
        address nftAddress,
        uint256 nftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken,
        address renter,
        OrderType orderType
    ) public whenNotPaused {
        privateOrderMap[nftAddress][nftId] = renter;
        paymentNormalMap[nftAddress][nftId] = PaymentNormal(
            paymentToken,
            pricePerDay
        );
        _createLendOrder(
            nftAddress,
            nftId,
            maxEndTime,
            minDuration,
            pricePerDay,
            paymentToken,
            orderType,
            PaymentType.Normal,
            renter
        );
    }

    function _createLendOrder(
        address nftAddress,
        uint256 nftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken,
        OrderType orderType,
        PaymentType paymentType,
        address renter
    ) internal {
        onlyApprovedOrOwner(msg.sender, nftAddress, nftId);
        require(maxEndTime > block.timestamp, "invalid maxEndTime");
        require(
            minDuration <= IComplexDoNFT(nftAddress).getMaxDuration(),
            "Error:minDuration > max"
        );
        require(
            IERC165(nftAddress).supportsInterface(
                type(IComplexDoNFT).interfaceId
            ),
            "not doNFT"
        );
        (, , uint64 dEnd) = IComplexDoNFT(nftAddress).getDurationByIndex(
            nftId,
            0
        );
        if (maxEndTime > dEnd) {
            maxEndTime = dEnd;
        }
        if (maxEndTime > block.timestamp + maxIndate) {
            maxEndTime = uint64(block.timestamp) + maxIndate;
        }

        address _owner = ERC721(nftAddress).ownerOf(nftId);
        Lending storage lending = lendingMap[nftAddress][nftId];
        lending.lender = _owner;
        lending.nftAddress = nftAddress;
        lending.nftId = nftId;
        lending.maxEndTime = maxEndTime;
        lending.minDuration = minDuration;
        lending.nonce = IComplexDoNFT(nftAddress).getNonce(nftId);
        lending.createTime = uint64(block.timestamp);
        lending.orderType = orderType;
        lending.paymentType = paymentType;

        emit CreateLendOrder(
            _owner,
            nftAddress,
            nftId,
            maxEndTime,
            minDuration,
            pricePerDay,
            paymentToken,
            renter,
            orderType
        );
    }

    function cancelLendOrder(address nftAddress, uint256 nftId)
        public
        whenNotPaused
    {
        onlyApprovedOrOwner(msg.sender, nftAddress, nftId);
        delete lendingMap[nftAddress][nftId];
        delete paymentNormalMap[nftAddress][nftId];
        delete privateOrderMap[nftAddress][nftId];
        emit CancelLendOrder(msg.sender, nftAddress, nftId);
    }

    function getLendOrder(address nftAddress, uint256 nftId)
        public
        view
        returns (Lending memory)
    {
        return lendingMap[nftAddress][nftId];
    }

    function getRenterOfPrivateLendOrder(address nftAddress, uint256 nftId)
        external
        view
        returns (address)
    {
        return privateOrderMap[nftAddress][nftId];
    }

    function getPaymentNormal(address nftAddress, uint256 nftId)
        external
        view
        returns (PaymentNormal memory)
    {
        return paymentNormalMap[nftAddress][nftId];
    }

    function fulfillOrderNow(
        address nftAddress,
        uint256 nftId,
        uint256 durationId,
        uint64 duration,
        address user
    ) public payable virtual whenNotPaused nonReentrant returns (uint256 tid) {
        require(isLendOrderValid(nftAddress, nftId), "invalid order");
        Lending storage lending = lendingMap[nftAddress][nftId];
        if (lending.orderType == OrderType.Private) {
            require(
                msg.sender == privateOrderMap[nftAddress][nftId],
                "invalid renter"
            );
        }
        uint64 endTime = uint64(block.timestamp + duration - 1);
        if (endTime > lending.maxEndTime) {
            endTime = lending.maxEndTime;
        }
        (, uint64 dEnd) = IComplexDoNFT(nftAddress).getDuration(durationId);
        if (endTime > dEnd) {
            endTime = dEnd;
        }
        uint64 startTime = uint64(block.timestamp);
        if (!(endTime == dEnd || endTime == lending.maxEndTime)) {
            require(duration >= lending.minDuration, "duration < minDuration");
        }
        distributePayment(nftAddress, nftId, startTime, endTime);
        tid = IComplexDoNFT(nftAddress).mint(
            nftId,
            durationId,
            startTime,
            endTime,
            msg.sender,
            user
        );
        PaymentNormal storage pNormal = paymentNormalMap[nftAddress][nftId];
        emit FulfillOrder(
            user,
            lending.lender,
            nftAddress,
            nftId,
            startTime,
            endTime,
            pNormal.pricePerDay,
            tid,
            pNormal.token
        );
    }

    function distributePayment(
        address nftAddress,
        uint256 nftId,
        uint64 startTime,
        uint64 endTime
    )
        internal
        returns (
            uint256 totalPrice,
            uint256 leftTotalPrice,
            uint256 curFee,
            uint256 curRoyalty
        )
    {
        PaymentNormal storage pNormal = paymentNormalMap[nftAddress][nftId];
        totalPrice = (pNormal.pricePerDay * (endTime - startTime + 1)) / 86400;
        curFee = (totalPrice * fee) / E5;
        curRoyalty =
            (totalPrice * IComplexDoNFT(nftAddress).getRoyaltyFee()) /
            E5;
        leftTotalPrice = totalPrice - curFee - curRoyalty;

        royaltyMap[nftAddress][pNormal.token] += curRoyalty;
        balanceOfFee[pNormal.token] += curFee;

        if (pNormal.token == address(0)) {
            require(msg.value >= totalPrice, "payment is not enough");
            payable(ERC721(nftAddress).ownerOf(nftId)).transfer(leftTotalPrice);
            if (msg.value > totalPrice) {
                payable(msg.sender).transfer(msg.value - totalPrice);
            }
        } else {
            uint256 balance_before = IERC20(pNormal.token).balanceOf(
                address(this)
            );
            SafeERC20.safeTransferFrom(
                IERC20(pNormal.token),
                msg.sender,
                address(this),
                totalPrice
            );
            uint256 balance_after = IERC20(pNormal.token).balanceOf(
                address(this)
            );
            require(
                balance_before + totalPrice == balance_after,
                "not support burn ERC20"
            );
            SafeERC20.safeTransfer(
                IERC20(pNormal.token),
                ERC721(nftAddress).ownerOf(nftId),
                leftTotalPrice
            );
        }
    }

    function setFee(uint256 fee_) public onlyAdmin {
        require(fee_ <= 1e4, "invalid fee");
        fee = fee_;
    }

    function getFee() public view returns (uint256) {
        return fee;
    }

    function setMarketBeneficiary(address payable beneficiary_)
        public
        onlyOwner
    {
        beneficiary = beneficiary_;
    }

    function claimFee(address[] calldata paymentTokens)
        public
        whenNotPaused
        nonReentrant
    {
        require(msg.sender == beneficiary, "not beneficiary");
        for (uint256 index = 0; index < paymentTokens.length; index++) {
            uint256 balance = balanceOfFee[paymentTokens[index]];
            if (balance > 0) {
                if (paymentTokens[index] == address(0)) {
                    beneficiary.transfer(balance);
                } else {
                    SafeERC20.safeTransfer(
                        IERC20(paymentTokens[index]),
                        beneficiary,
                        balance
                    );
                }
                balanceOfFee[paymentTokens[index]] = 0;
            }
        }
    }

    function balanceOfRoyalty(address nftAddress, address paymentToken)
        public
        view
        returns (uint256)
    {
        return royaltyMap[nftAddress][paymentToken];
    }

    function claimRoyalty(address nftAddress, address[] calldata paymentTokens)
        public
        whenNotPaused
        nonReentrant
    {
        address payable _beneficiary = IComplexDoNFT(nftAddress)
            .getBeneficiary();
        require(msg.sender == _beneficiary, "not beneficiary");
        for (uint256 index = 0; index < paymentTokens.length; index++) {
            uint256 balance = royaltyMap[nftAddress][paymentTokens[index]];
            if (balance > 0) {
                if (paymentTokens[index] == address(0)) {
                    _beneficiary.transfer(balance);
                } else {
                    SafeERC20.safeTransfer(
                        IERC20(paymentTokens[index]),
                        _beneficiary,
                        balance
                    );
                }
                royaltyMap[nftAddress][paymentTokens[index]] = 0;
            }
        }
    }

    function isLendOrderValid(address nftAddress, uint256 nftId)
        public
        view
        returns (bool)
    {
        Lending storage lending = lendingMap[nftAddress][nftId];
        if (isPausing) {
            return false;
        }
        return
            lending.nftId > 0 &&
            lending.maxEndTime > block.timestamp &&
            lending.nonce == IComplexDoNFT(nftAddress).getNonce(nftId);
    }

    function setPause(bool pause_) public onlyAdmin {
        isPausing = pause_;
        if (isPausing) {
            emit Paused(address(this));
        } else {
            emit Unpaused(address(this));
        }
    }

    function setMaxIndate(uint64 max_) public onlyAdmin {
        maxIndate = max_;
    }
}
