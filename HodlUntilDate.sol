pragma solidity ^0.4.23;

/// @title Prevents withdrawal of funds until a certain date has passed
/// @author Matt O'Leary - <matthew.oleary@gmail.com>
/// Note: while the block timestamp could be manipulated in the short term by the miners, 
/// thus allowing or preventing the funds being transferred, they would still need the private key in order to actually do anything with the ETH
/// Also nodes will reject the block if its in the future, so its not going to be worth it to the miners to fudge the block timestamp to retrieve the ETH
contract HodlUntilDate {
    uint256 public hodlDate;   // Funds cannot be withdrawn until this date & time
    address public owner;

    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }
    modifier onlyAfterHodlDate() {
        require(block.timestamp >= hodlDate, "Cannot withdraw until the HODL date");
        _;
    }
    modifier onlyIfHasAvailableBalance() {
        require(getAvailableBalance() > 0, "Available balance must be greater than zero");
        _;
    }
    
    constructor(uint256 _hodlDate) public payable {
    
        // https://ethereum.stackexchange.com/questions/18192/how-do-you-work-with-date-and-time-on-ethereum-platform
        // The block includes a timestamp (in seconds since 1970), which your contract code can refer to by the name now
        require(_hodlDate > block.timestamp,"hodlDate must be later than the current block timestamp");
        require(_hodlDate < (block.timestamp + 10 years),"hodlDate cannot be more than 10 years in the future");
        
        hodlDate = _hodlDate;
        owner = msg.sender;
    }
    
    // Withdraw all or part of the available balance to the specified address
    function withdraw(address toAddress, uint256 amount) public
        onlyBy(owner)
        onlyAfterHodlDate()
        onlyIfHasAvailableBalance() {

        require(amount > 0, "Amount to withdraw must be greater than zero");

        // TODO: We are calculating the available balance twice... 
        //       need to measure gas, and refactor to see what the difference is

        require(amount <= getAvailableBalance(), "Amount must be less than or equal to the available balance");

        // Note: remix gives a Gas requirement infinite warning for this next line
        //       but its safe to ignore.  It just means the caller must use sufficient gas so that the transfer goes through
        toAddress.transfer(amount);
        
        // TODO: possibly selfdestruct if the balance is zero and the hodlDate is in the past
        //       but does this open up an attack vector (eg Parity hack)? 
        //       Is it worth any benefit since it doesnt cost anything to keep the contract alive?
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getAvailableBalance() public view returns (uint256) {
        if (block.timestamp < hodlDate) {
            return 0;
        }
        else {
            return address(this).balance;
        }
    }

    // Allows moving the hodl date back (but not forwards), even if its already in the past
    function extendHodlDate(uint256 _hodlDate) public {
        require(_hodlDate > hodlDate, "The new HODL date must be after the current HODL date");
        require(_hodlDate < (block.timestamp + 10 years),"hodlDate cannot be more than 10 years in the future");

        hodlDate = _hodlDate; 
    }

    // Fallback function for receiving payments
    function() public payable {
        // Don't need to do anything
    }
}

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
