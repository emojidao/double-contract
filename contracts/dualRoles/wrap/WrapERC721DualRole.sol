// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC4907.sol";
import "./IWrapNFT.sol";

contract WrapERC721DualRole is ERC4907, IWrapNFT {
    address private _originalAddress;

    address private _doNFTAddress;

    constructor(
        string memory name_,
        string memory symbol_,
        address originalAddress_
    ) ERC4907(name_, symbol_) {
        require(_originalAddress == address(0), "inited already");
        require(
            IERC165(originalAddress_).supportsInterface(
                type(IERC721).interfaceId
            ),
            "not ERC721"
        );
        _originalAddress = originalAddress_;
    }

    function originalAddress() public view returns (address) {
        return _originalAddress;
    }

    function stake(uint256 tokenId) public returns (uint256) {
        require(
            onlyApprovedOrOwner(msg.sender, _originalAddress, tokenId),
            "only approved or owner"
        );
        address lastOwner = ERC721(_originalAddress).ownerOf(tokenId);
        ERC721(_originalAddress).safeTransferFrom(
            lastOwner,
            address(this),
            tokenId
        );
        _mint(lastOwner, tokenId);
        emit Stake(msg.sender, _originalAddress, tokenId);
        return tokenId;
    }

    function redeem(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        ERC721(_originalAddress).safeTransferFrom(
            address(this),
            ownerOf(tokenId),
            tokenId
        );
        _burn(tokenId);
        emit Redeem(msg.sender, _originalAddress, tokenId);
    }

    function onlyApprovedOrOwner(
        address spender,
        address nftAddress,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = ERC721(nftAddress).ownerOf(tokenId);
        require(
            owner != address(0),
            "ERC721: operator query for nonexistent token"
        );
        return (spender == owner ||
            ERC721(nftAddress).getApproved(tokenId) == spender ||
            ERC721(nftAddress).isApprovedForAll(owner, spender));
    }

    function originalOwnerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner)
    {
        owner = ERC721(_originalAddress).ownerOf(tokenId);
        if (owner == address(this)) {
            owner = ownerOf(tokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return ERC721(_originalAddress).tokenURI(tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure virtual override returns (bytes4) {
        bytes4 received = 0x150b7a02;
        return received;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IWrapNFT).interfaceId ||
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
