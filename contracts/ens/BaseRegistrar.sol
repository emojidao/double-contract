// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface BaseRegistrar {
    
    function nameExpires(uint256 id) external view returns(uint);

    function reclaim(uint256 id, address owner) external;
    
}
