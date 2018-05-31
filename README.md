# eth-smart-contracts
A selection of Ethereum smart contracts that I have developed while learning Solidity


> ## Disclaimer
> This is experimental software and has not been tested thoroughly, and the code has not been  audited for security vulnerabilities.  
> 
> If you deploy to the Ethereum mainnet, its at your own risk! 
> 

<br>

### HodlUntilDate
Smart Contract which allows locking any funds received by the address for a specified period of time.  Note: this relies on the block timestamp so is vulnerable to manipulation from miners, however the risk is small as the miner would have to put the timestamp in the past, and risk having their blocks rejected by the network. 

### HodlUntilDateUnlessReleased
Similar to HodlUntilDate contract (inherits from it), but gives a secondary address the ability to release all or part of the balance immediately. 

### OddOrEvenContestContract
A simple mechanism for determining the winner between 2 addresses.  One address is the "even" address, the other is the "odd" address.<br>
Each address provides a number (usually randomly created), and if the sum of the 2 numbers is even, the "even" address is the winner; and if the sum of the 2 numbers is odd, then the "odd" number is the winner.<br>
This is a library contract which can be called by another smart contract, for example to determine who should start a game.

### Connect4Contract (Work in progress)
Smart contract allowing 2 players (ethereum addresses) to play a game of Connect4 with a real stake of Ether.  The OddOrEvenContestContract is used to determine which player goes first.