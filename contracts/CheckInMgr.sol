// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableContract.sol";

contract CheckInMgr is OwnableContract {
    struct CheckInData {
        uint256 oid;
        address user;
        uint64 expiredAt;
    }

    mapping(uint256 => CheckInData) checkInMap;

    function resetExpiredTo(uint256[] memory ids, address to)
        public
        virtual
        onlyAdmin
    {
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 oid = ids[index];
            if (isCheckInDataExpired(oid)) {
                setUser(oid, to, 0);
            }
        }
    }

    function isCheckInDataExpired(uint256 oid) public view returns (bool) {
        return checkInMap[oid].expiredAt < block.timestamp;
    }

    function setUser(
        uint256 oid,
        address to,
        uint64 expiredAt
    ) internal virtual {
        checkInMap[oid] = CheckInData(oid, to, expiredAt);
    }
}
