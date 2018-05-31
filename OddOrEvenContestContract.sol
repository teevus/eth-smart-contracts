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
        bytes32 id;
        
        address oddPlayer;  // Player that wins if the total is odd
        address evenPlayer; // Player that win if the total is even
        
        bytes32 oddPlayerNumberHash;
        bytes32 evenPlayerNumberHash;
        
        uint128 oddPlayerNumber;
        uint128 evenPlayerNumber;
        
        ContestStage stage;
    }
    
    modifier onlyIfIdValid(bytes32 id) {
        require(id.length > 0, "id is required");
        _;
    }
    modifier onlyIfIdExists(bytes32 id) {
        require(contests[id].id.length > 0, 'Contest does not exist for the specified id');
        _;
    }
    modifier onlyIfIdDoesNotExist(bytes32 id) {
        require(contests[id].id.length == 0, "id must be unique (Contest already exists with this id");
        _;
    }
    modifier onlyByEitherPlayer(bytes32 id) {
        Contest storage contest = contests[id];
        require(msg.sender == contest.oddPlayer || msg.sender == contest.evenPlayer, "Function can only be called by either of the players related to the contest.");
        _;
    }

    mapping (bytes32 => Contest) public contests;
    mapping (bytes32 => address) public results;

    constructor() public {
        // Nothing to do
    }
    
    function startContest(bytes32 id, address oddPlayer, address evenPlayer) public 
                onlyIfIdValid(id)
                onlyIfIdDoesNotExist(id) {

        require(oddPlayer != 0, "Odd Player address cannot be zero");
        require(evenPlayer != 0, "Even Player address cannot be zero");
        require(oddPlayer != evenPlayer, "Odd Player and Even Player addresses must be different");
        
        Contest memory newContest = Contest({
            id: id,
            oddPlayer: oddPlayer,
            evenPlayer: evenPlayer,
            stage: ContestStage.Commit,
            oddPlayerNumberHash: "",
            evenPlayerNumberHash: "",
            oddPlayerNumber: 0,
            evenPlayerNumber: 0
        });
        
        contests[id] = newContest;
    }
    
    // Each player should call this, to publish the hashed version of their value
    function commit(bytes32 id, bytes32 numberHash) public 
            onlyIfIdValid(id)
            onlyIfIdExists(id)
            onlyByEitherPlayer(id) {
        
        Contest storage contest = contests[id];
        require(contest.stage == ContestStage.Commit, "Contest must be at the Commit stage");
         
        
        // Note: it doesnt matter if they have already provided a value, as long as both players havent yet, we just overwrite
        if (msg.sender == contest.oddPlayer) {
            contest.oddPlayerNumberHash = numberHash;
        }
        else if (msg.sender == contest.evenPlayer) {
            contest.evenPlayerNumberHash = numberHash;
        }
        
        if (contest.evenPlayerNumberHash != "" && contest.oddPlayerNumberHash != "") {
            contest.stage = ContestStage.Reveal;
        }
    }
    
    // Each player should call this, to reveal their actual value
    function reveal(bytes32 id, uint128 actualValue, bytes32 salt) public 
                onlyIfIdValid(id)
                onlyIfIdExists(id)
                onlyByEitherPlayer(id) {
        
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
            uint sum = contest.oddPlayerNumber + contest.evenPlayerNumber;
            if (sum % 2 == 1) {
                // Odd player wins
                results[id] = contest.oddPlayer;
            }
            else {
                // Even player wins
                results[id] = contest.evenPlayer;
            }

            contest.stage = ContestStage.Result;
        }
    }
    
    function verifyHash(bytes32 hash, uint128 actualValue, bytes32 salt) private pure returns (uint128) {
        bytes32 calculatedHash = keccak256(actualValue, salt);
        
        require(hash == calculatedHash, "Hash value of actualValue doesnt match hash value provided during Commit stage.");
        
        return actualValue;
    }

    

}