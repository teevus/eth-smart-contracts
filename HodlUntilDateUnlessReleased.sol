pragma solidity ^0.4.23;
import "./HodlUntilDate.sol";

/// @title HoldUntil contract where the second account can release (unlock) an amount
/// that can then be withdrawn by the owner of the contract prior to the HODL date 
contract HodlUntilDateUnlessReleased is HodlUntilDate {
    
    uint256 releasedBalance;
    address secondaryAccount;
    
    constructor(uint256 _hodlDate, address _secondaryAccount) HodlUntilDate(_hodlDate) public payable {
        require(_secondaryAccount != owner, "Secondary Account can't be the same address as the owner of the contract");
    
        secondaryAccount = _secondaryAccount; 
    }
    
    function withdraw(address toAddress, uint256 amount) public {
        super.withdraw(toAddress, amount);
        
        // Implementation provided by the parent HodlUntilDate contract, all that needs to be done now is to update the releasedBalance
        // Note: we could withdraw more than the releasedBalance if the hodl date is in the past, so we need to handle this scenario
        if (releasedBalance > amount) {
            releasedBalance = releasedBalance - amount;
        }
        else {
            releasedBalance = 0;
        }
    }

    function getUnreleasedBalance() public view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        assert(contractBalance >= releasedBalance);
        
        uint256 unreleasedBalance = contractBalance - releasedBalance;
        
        return unreleasedBalance;
    }

    function getAvailableBalance() public view returns (uint256) {
        if (block.timestamp < hodlDate) {
            return releasedBalance;
        }
        else {
            return address(this).balance;
        }
    }

    function release(uint256 amount) public
                onlyBy(secondaryAccount) {
        
        require(amount > 0, "Amount must be greater than zero");
        
        uint256 unreleasedBalance = getUnreleasedBalance();
        require(amount <= unreleasedBalance, "Unreleased balance must be greater than zero");
        
        releasedBalance = releasedBalance + amount;
        
        assert(releasedBalance <= address(this).balance);
    }
    
    function releaseAll() public                 
                onlyBy(secondaryAccount) {
                    
        uint256 unreleasedBalance = getUnreleasedBalance();
        require(unreleasedBalance > 0, "Unreleased balance must be greater than zero");
        
        releasedBalance = releasedBalance + unreleasedBalance;
        
        assert(releasedBalance == address(this).balance);
    }
}
