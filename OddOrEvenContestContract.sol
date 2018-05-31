pragma solidity ^0.4.23;

// Smart contract for a simple method to decide on a winner in a contest between 2 addresses
// For example, to determine who goes first in a game of Connect4
// It also provides the ability for other smart contracts on the Ethereum network to verify the results
// This smart contract has no payable method and therefore its not possible to send ETH to this contract

// Note: To keep gas costs down, this contract will remain live and can be used for multiple contests
// There is no selfdestruct call TODO: ensure this is not provided by default

// TODO: To reduce storage accumulating over time, old contest details can be purged, 
// and just the result is kept.  Results can be viewed by anybody

// Using the commit/reveal pattern: https://karl.tech/learning-solidity-part-2-voting/
contract OddOrEvenGameContract {
    
    enum ContestStage {
        Commit,
        Reveal,
        Result
    }

    struct Contest {
        
        address oddPlayer;  // Player that wins if the total is odd
        address evenPlayer; // Player that win if the total is even
        
        bytes32 oddPlayerNumberHash;
        bytes32 evenPlayerNumberHash;
        
        uint128 oddPlayerNumber;
        uint128 evenPlayerNumber;
        
        address winner;
        
        ContestStage stage;
    }

    uint nextId;


    mapping (uint => Contest) public contests;
    mapping (uint => uint) public results;

    constructor() public {
        // Nothing to do
    }
    
    function startContest(address oddPlayer, address evenPlayer) public returns (uint) {
        nextId = nextId + 1;
        
        Contest memory newContest = Contest({
            oddPlayer: oddPlayer,
            evenPlayer: evenPlayer,
            stage: ContestStage.Commit,
            oddPlayerNumberHash: "",
            evenPlayerNumberHash: "",
            oddPlayerNumber: 0,
            evenPlayerNumber: 0,
            winner: 0 // Empty address
        });
        
        contests[nextId] = newContest;
        
        return nextId;
    }
    
    // Each player should call this, to publish the hashed version of their value
    function commit(uint id, bytes32 numberHash) public {
        Contest storage contest = contests[id];
        require(contest.stage == ContestStage.Commit, "Contest must be at the Commit stage");
         
        // Note: it doesnt matter if they have already provided a value, as long as both players havent yet, we just overwrite
        if (msg.sender == contest.oddPlayer) {
            contest.oddPlayerNumberHash = numberHash;
        }
        else {
            contest.evenPlayerNumberHash = numberHash;
        }
        
        if (contest.evenPlayerNumberHash != "" && contest.oddPlayerNumberHash != "") {
            contest.stage = ContestStage.Reveal;
        }
    }
    
    // Each player should call this, to reveal their actual value
    function reveal(uint id, uint128 actualValue, bytes32 salt) public {
        
        Contest storage contest = contests[id];
        
        require(contest.stage == ContestStage.Reveal, "Contest is not at Reveal stage");
        
        if (contest.oddPlayer == msg.sender) {
            // Odd Player is revealing
            contest.oddPlayerNumber = verifyHash(contest.oddPlayerNumberHash, actualValue, salt);
        }
        else {
            // Even Player is revealing
            contest.evenPlayerNumber = verifyHash(contest.oddPlayerNumberHash, actualValue, salt);
        }
        
        // If both players have revealed then calculate the result
        if (contest.oddPlayerNumber > 0 && contest.evenPlayerNumber > 0) {
            uint sum = contest.oddPlayerNumber + contest.evenPlayerNumber; // TODO: What if this is bigger than maximum uint256
            results[id] = sum;
            contest.stage = ContestStage.Result;
        }
    }
    
    function verifyHash(bytes32 hash, uint128 actualValue, bytes32 salt) private returns (uint128) {
        bytes32 calculatedHash = keccak256(actualValue, salt);
        
        require(hash == calculatedHash, "Hash value of actualValue doesnt match hash value provided during Commit stage.");
        
        return actualValue;
    }
    
    
    
    
}