// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IRoyalty.sol";

contract Royalty is IRoyalty {
    /** percent = fee/100000 */
    uint256 private fee;
    address payable private beneficiary;
    address public royaltyAdmin;
    address public tempRoyaltyAdmin;

    modifier onlyRoyaltyAdmin() {
        require(msg.sender == royaltyAdmin, "onlyAdmin");
        _;
    }

    function setTempRoyaltyAdmin(address tempAdmin_) public virtual {
        require(msg.sender == royaltyAdmin, "not royaltyAdmin");
        require(tempAdmin_ != address(0) && tempAdmin_ != royaltyAdmin);
        tempRoyaltyAdmin = tempAdmin_;
    }

    function claimRoyaltyAdmin() public virtual {
        require(msg.sender == tempRoyaltyAdmin, "not tempRoyaltyAdmin");
        royaltyAdmin = payable(tempRoyaltyAdmin);
        tempRoyaltyAdmin = address(0);
        emit ClaimRoyaltyAdmin(msg.sender);
    }

    function setBeneficiary(address payable beneficiary_)
        public
        virtual
        onlyRoyaltyAdmin
    {
        require(beneficiary_ != address(0) && beneficiary_ != beneficiary);
        beneficiary = beneficiary_;
        emit SetBeneficiary(msg.sender, beneficiary);
    }

    function getBeneficiary() external view returns (address payable) {
        return beneficiary;
    }

    function setRoyaltyFee(uint256 fee_) public virtual onlyRoyaltyAdmin {
        require(fee_ <= 10000, "fee exceeds 10pct");
        fee = fee_;
        emit SetRoyaltyFee(msg.sender, fee);
    }

    function getRoyaltyFee() public view returns (uint256) {
        return fee;
    }
}
