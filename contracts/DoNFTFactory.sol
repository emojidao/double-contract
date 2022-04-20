// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableContract.sol";
import "./IComplexDoNFT.sol";
import "./dualRoles/wrap/WrapERC721DualRole.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DoNFTFactory is OwnableContract{

    event DeployDoNFT(address proxy,string name, string symbol,address originalAddress,address market,address tempRoyaltyAdmin,string gameKey);

    event DeployWrapERC721DualRole(address wrapNFT,string name, string symbol,address originalAddress);

    mapping(address => mapping(string => address)) private wrapDoNftMap;

    address public beacon;

    constructor(){
        initOwnableContract();
    }

    function deployWrapDoNFT(string memory name, string memory symbol,address originalAddress,address market,address tempRoyaltyAdmin,string calldata gameKey) external returns(BeaconProxy proxy) {
        require(IERC165(originalAddress).supportsInterface(type(IERC721).interfaceId),"not ERC721");
        require(wrapDoNftMap[originalAddress][gameKey] == address(0),"already create");
        bytes memory _data = abi.encodeWithSignature("initialize(string,string,address,address,address)",name,symbol,originalAddress,market,tempRoyaltyAdmin);
        proxy = new BeaconProxy(beacon,_data);
        wrapDoNftMap[originalAddress][gameKey] = address(proxy);
        emit DeployDoNFT(address(proxy),name,symbol,originalAddress,market,tempRoyaltyAdmin,gameKey);
    }

    function deployWrapERC721DualRole(string memory name, string memory symbol,address originalAddress) public returns(WrapERC721DualRole wrapNFT){
        require(IERC165(originalAddress).supportsInterface(type(IERC721).interfaceId),"not ERC721");
        wrapNFT = new WrapERC721DualRole(name,symbol,originalAddress);
        emit DeployWrapERC721DualRole(address(wrapNFT),name,symbol,originalAddress);
    }

    function setBeacon(address beacon_) public onlyAdmin {
        beacon = beacon_;
    }

    function getWrapProxy(address nftAddress,string calldata gameKey) public view returns(address){
        return wrapDoNftMap[nftAddress][gameKey];
    }

}
