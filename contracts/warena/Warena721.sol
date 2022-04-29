// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract Warena721 is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    using SafeMath for uint256;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    IERC20 private _token;
    address private _addressReceiveTokenOpenBox;
    bool private _turnOnOpenBox = true;
    address private constant DEFAULT_TOKEN_OPEN_BOX =
        0xa9D75Cc3405F0450955050C520843f99Aff8749D;

    uint256 public amountRequireMint = 30000000000000000000;

    mapping(bytes32 => bool) public messageHash;

    mapping(uint256 => string) private _idTokenToHash;

    mapping(string => uint256) private _hashToTokenId;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _base721URI;

    constructor() ERC721("", "") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _token = IERC20(DEFAULT_TOKEN_OPEN_BOX);
        _addressReceiveTokenOpenBox = msg.sender;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
        override
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _idTokenToHash[tokenId] = _tokenURI;
        _hashToTokenId[_tokenURI] = tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return
            "https://infura-ipfs.io/ipfs/bafkreihbegouxsgbc3pexvoplueouzoaegpqc5ariibtjqahi4bfqvjl3q";
    }

    function setBase721URI(string memory newBase721Url)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _base721URI = newBase721Url;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _base721URI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setOwner(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    function setMinter(address newMinter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, newMinter);
    }

    function setTokenOpenBox(address ierc20Address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _token = IERC20(ierc20Address);
    }

    function setTotalTokenOpenBox(uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        amountRequireMint = amount;
    }

    function safeMint(address to, uint256 tokenId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _safeMint(to, tokenId);
    }

    function setTurnOnOpenBox(bool turnOnOpenBox)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _turnOnOpenBox = turnOnOpenBox;
    }

    function getAmountRequireMint() public view returns (uint256) {
        return amountRequireMint;
    }

    function setAddressReceiveTokenOpenBox(address addressReceiveTokenOpenBox)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _addressReceiveTokenOpenBox = addressReceiveTokenOpenBox;
    }

    function safeMint(
        address to,
        uint256 tokenId,
        uint256 blockExpiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory metadataURI
    ) public {
        // require(
        //     blockExpiry >= block.number,
        //     "signature expired"
        // );

        // bytes32 msgHash = prepareMintHash(to, tokenId, blockExpiry);
        // require(
        //     hasRole(MINTER_ROLE ,ecrecover(msgHash, v, r, s)), "in correct signer"
        // );
        // require(!messageHash[msgHash], "signature duplicate");

        // messageHash[msgHash] = true;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);

        // return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintToken(address owner, string memory metadataURI)
        external
        returns (uint256)
    {
        // require(_turnOnOpenBox, "The Open Box Day Hasn't Come Yet");
        // require(_token.balanceOf(_msgSender())>=amountRequireMint, "Not Enough Token To Open Box");
        // _token.safeTransferFrom(_msgSender(), _addressReceiveTokenOpenBox, amountRequireMint);
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(owner, newTokenId);
        _setTokenURI(newTokenId, metadataURI);
        return newTokenId;
    }

    function prepareMintHash(
        address to,
        uint256 id,
        uint256 blockExpiry
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encodePacked(
                            abi.encodePacked(this, id, blockExpiry, to)
                        )
                    )
                )
            );
    }
}
