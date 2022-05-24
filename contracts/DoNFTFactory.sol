// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableContract.sol";
import "./IComplexDoNFT.sol";
import "./dualRoles/wrap/WrapERC721DualRole.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DoNFTFactory is OwnableContract {
    event DeployDoNFT(
        address proxy,
        string name,
        string symbol,
        address originalAddress,
        address market,
        address royaltyAdmin,
        string gameKey
    );

    event DeployWrapERC721DualRole(
        address wrapNFT,
        string name,
        string symbol,
        address originalAddress
    );

    mapping(address => mapping(string => address)) private doNftMapping;

    address public beacon;
    address public market;

    constructor(address owner_,address admin_,address beacon_,address market_) {
        initOwnableContract(owner_, admin_);
        beacon = beacon_;
        market = market_;
    }

    function setBeaconAndMarket(address beacon_, address market_)
        public
        onlyAdmin
    {
        beacon = beacon_;
        market = market_;
    }

    function deployDoNFT(
        string memory name,
        string memory symbol,
        address originalAddress,
        address owner_,
        address admin_,
        address royaltyAdmin,
        string calldata gameKey
    ) external returns (BeaconProxy proxy) {
        require(
            IERC165(originalAddress).supportsInterface(
                type(IERC4907).interfaceId
            ),
            "original NFT is not IERC4907"
        );
        require(
            doNftMapping[originalAddress][gameKey] == address(0),
            "depolyed already"
        );
        bytes memory _data = abi.encodeWithSignature(
            "initialize(string,string,address,address,address,address,address)",
            name,
            symbol,
            originalAddress,
            market,
            owner_,
            admin_,
            royaltyAdmin
        );
        proxy = new BeaconProxy(beacon, _data);
        doNftMapping[originalAddress][gameKey] = address(proxy);
        emit DeployDoNFT(
            address(proxy),
            name,
            symbol,
            originalAddress,
            market,
            royaltyAdmin,
            gameKey
        );
    }

    function deployWrapNFT(
        string memory name,
        string memory symbol,
        address originalAddress
    ) public returns (WrapERC721DualRole wrapNFT) {
        require(
            IERC165(originalAddress).supportsInterface(
                type(IERC721).interfaceId
            ),
            "not ERC721"
        );
        require(
            !IERC165(originalAddress).supportsInterface(
                type(IERC4907).interfaceId
            ),
            "the NFT is IERC4907 already"
        );

        wrapNFT = new WrapERC721DualRole(name, symbol, originalAddress);
        emit DeployWrapERC721DualRole(
            address(wrapNFT),
            name,
            symbol,
            originalAddress
        );
    }

    function getDoNFT(address nftAddress, string calldata gameKey)
        public
        view
        returns (address)
    {
        return doNftMapping[nftAddress][gameKey];
    }
}
