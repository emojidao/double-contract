// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ENS {
    function owner(bytes32 node) external  view returns (address);
    
}
