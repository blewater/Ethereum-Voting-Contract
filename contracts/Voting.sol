pragma solidity ^0.5.0;

/**
 * Assignment Main Voting Contract for Parts 1, 2
 *
 * Release Notes for this contract in Submission 2:
 * Vonting Enum removed.
 * Voting events collapsed to one.
 * Require(s) changed to modifiers except for the remote call case. See below isOwner.
 * Standardized modifier strings to eliminate typo issues in require exceptions.
 * 
 */

/**
 * Contract ManyOwners encapsulates multiple owner functionality for part 2.
 * of assignment.
 */
import "./ManyOwners.sol";
import "./Wa.sol";

contract Voting is ManyOwners() ,Wa() {

//--------------------------------------------------------
//------------------- Storage Declarations

    // Number of verified voters
    uint16 TotalNumberOfVoters = 0;

    // Bit values to encode a winning votes byte
    // See function getWinnersByte() below
    bytes1 constant ZERO_VOTES_BIT = 0x01;
    bytes1 constant ONE_VOTES_BIT = 0x02;
    bytes1 constant TWO_VOTES_BIT = 0x04;

    // Accummulated votes
    uint ZeroVotesCount = 0;
    uint OneVotesCount = 0;
    uint TwoVotesCount = 0;

    // Default voter status is Unverified
    mapping (address => bool) VerifiedVoters;

//--------------------------------------------------------------------------------
//------------------------ Events Declarations

event Voter_Verified(address ownerAddress, address voterAddress);
event Redudant_Voter_Verification(address ownerAddress, address voterAddress);
event Vote_Cast(uint8 castVote, uint zeroVoteCount, uint oneVoteCount, uint twoVoteCount);
event Received_Funds(address sender, uint amount);
event Refunded_Funds_Succeeded(address recipient, uint amount);

//--------------------------------------------------------------------------------
//------------------------ Modifier Declarations

    //
    // Limit number of loop iterations by the constructor
    //
    uint16 MAX_ITERATIONS = 10000; // 10K

    modifier onlyMaxLoopIterations(uint loopLength) {
        require(loopLength <= MAX_ITERATIONS, 
        "VREQ1: Cannot add more than 10000 Voters at a time.");
        _;
    }

    //
    // Limit number of voters by the constructor
    //
    uint MAX_VOTERS = 100000; // 100k

    modifier onlyMaxNumberOfVoters(uint numberOfVotersToAdd) {
        require(numberOfVotersToAdd + TotalNumberOfVoters <= MAX_VOTERS, 
        "VREQ2: Not allowing more than 100000 Voters.");
        _;
    }

    //
    // Constant string for remote call in require
    //
    string constant NOT_OWNER = "VREQ3: Not an owner.";

    //
    // Enforece votes to 0, 1, 2
    //
    modifier onlyValidVotes(uint8 castVote) {
        require(
            castVote >= 0 && castVote <= 2, 
            "VREQ4: Vote needs to be 0 or 1 or 2.");
        _;
    }

    //
    // Enforce verified voters
    //
    modifier onlyVerifiedVoters() {
        require(isVoterVerified(msg.sender), "VREQ5: Voter not verified to vote.");
        _;
    }

    //
    // Prevent invalid fallback calls.
    //
    modifier onlyValidFallbackCalls() {
        require(msg.data.length == 0, "VREQ6: Invalid fallback call()"); 
        _;
    }

    //
    // Prevent voting if any Mario is Prez.
    //
    modifier isVotingOpen() {
        require(!IsMarioPrez, "VREQ7: Voting has ended!"); 
        _;
    }

//------------------------------------------------------------------------------
//--------------------------- Public Functions

    /**
     * @dev Init contract's creator, voters, owners
     * @param oraclizeResAddr This address needs to be replaced
     *                        with the value from the ethereum-bridge launch
     *                        ethereum-bridge.cmd -a 9 -H 127.0.0.1 -p7545 --dev
     *                        Not required for a non-local blockchain.
     *
     * @param daysDelayForNextOraclizeQuery Days to wait before next query to Oraclize.
     *
     * @param inVoters addresses to verify as voters. May be empty.
     * @param inOwners addresses to add as owners. May be empty 
     *                  so the msg.sender acts as default single owner.
     */
    constructor(
        uint16 maxLoopIterations,
        uint maxVoters,
        address oraclizeResAddr,
        uint8 daysDelayForNextOraclizeQuery,
        address[] memory inVoters, 
        address[] memory inOwners) public payable {

        //
        // Used in modifiers: Loop, Voter restrictions.
        //
        MAX_ITERATIONS = maxLoopIterations;
        MAX_VOTERS = maxVoters;

        //
        // You may also add owner(s) later. 
        // See also addOwner()
        // 
        addOwners(inOwners);

        //
        // Verify any voters now. You may add more later.
        // See also verifyVoter()
        //
        verifyVoters(inVoters);

        //
        // Initialize oraclize parameters.
        //
        setupOraclize(oraclizeResAddr, daysDelayForNextOraclizeQuery);
    }

    /**
     * @dev Make multiple voters eligible again to vote if sender is an owner.
     * @dev Emit the Voter_Verified event.
     * @dev About security best practice of remote require calls: 
     * @dev https://github.com/ConsenSys/smart-contract-best-practices/blob/master/docs/recommendations.md#use-modifiers-only-for-assertions
     * @param votersAddress The address array of the voters.
     */
    function verifyVoters(address[] memory votersAddress) public 
            onlyMaxLoopIterations(votersAddress.length) 
            onlyMaxNumberOfVoters (votersAddress.length)
            onlyOwners()  {

        uint16 len = uint16(votersAddress.length);
        for (uint16 i = 0; i < len; i++) {

            // Reuse function for single addition
            verifyVoter(votersAddress[i]);
        }
    }

    /**
     * @dev Return whether the msg.sender is a verified voter.
     * @param user The address of the candidate voter.
     * @return True/False: whether a user is a verified voter.
     */
    function isVoterVerified(address user) public view returns (bool) {

        return VerifiedVoters[user];
    }

    /**
     * @dev Cast a vote if eligible. 
     * @dev Track the votes tally here and calculate
     * @dev the winners upon demand in getWinnerByte(), getWinnerDesc().
     * @param castVote uint8: the vote 0, 1, 2.
     * @return None but emits
     *      Zero_Vote_Cast
     *      or
     *      One_Vote_Cast 
     *      or
     *      Two_Vote_Cast events.
     */
    function vote(uint8 castVote) public 
        onlyValidVotes(castVote) 
        onlyVerifiedVoters 
        isVotingOpen {

        // Voters can vote once. Mark voter's ineligibility first.
        VerifiedVoters[msg.sender] = false;

        if (castVote == 0) {
            
            ZeroVotesCount++;
        }
        else if (castVote == 1) {
            
            OneVotesCount++;
        }
        else {

            TwoVotesCount++;
        }
            
        emit Vote_Cast(castVote, ZeroVotesCount, OneVotesCount, TwoVotesCount);
    }

    /**
     * @dev Make a voter eligible again to vote if sender is an owner.
     * @dev Emit the Voter_Verify event.
     * @param voterAddress The address of the voter.
     */
    function verifyVoter(address voterAddress) public 
            onlyMaxNumberOfVoters(1) 
            onlyOwners() {

        if (!isVoterVerified(voterAddress)) {

            TotalNumberOfVoters++;
        
            VerifiedVoters[voterAddress] = true;

            emit Voter_Verified(msg.sender, voterAddress);

        } else {

            emit Redudant_Voter_Verification(msg.sender, voterAddress);
        }
    }

    /**
     * @dev Return the winners by signaling bits: 
     * @dev     0x1 -> Zero, 0x2 -> One, 0x4 -> Two
     * @dev Note call getWinnersDesc() for a friendly string 
     * @dev     description of this result.
     * @dev Examples:
     * @dev     0x5 -> Votes 0, 2 won the ballot. 
     * @dev     0x7 all three votes won the ballot. 
     * @dev     0x1 Zero vote alone won the ballot.
     * @return one byte with ON bits signaling winnning vote(s).
     */
    function getWinnersByte() public view returns (bytes1) {

        bytes1 winnersBits;
        uint localZeroVotesCount = ZeroVotesCount;
        uint localOneVotesCount = OneVotesCount;
        uint localTwoVotesCount = TwoVotesCount;

        //
        // Determine which vote(s) won.
        // Same logic thrice 
        //      Step 1: if a vote type is greater or equal to the other 2
        //      Step 2: Mark it as winner
        //      Step 3: Mark any of the other 2 winning if equal to step 2 winner.
        //
        if (localZeroVotesCount >= localOneVotesCount && localZeroVotesCount >= localTwoVotesCount) {
            winnersBits = ZERO_VOTES_BIT;
            if (localZeroVotesCount == localOneVotesCount) {
                winnersBits = winnersBits | ONE_VOTES_BIT;
            }
            if (localZeroVotesCount == localTwoVotesCount) {
                winnersBits = winnersBits | TWO_VOTES_BIT;
            }
        }
        else if (localOneVotesCount >= localZeroVotesCount && localOneVotesCount >= localTwoVotesCount) {
            winnersBits = ONE_VOTES_BIT;
            if (localOneVotesCount == localZeroVotesCount) {
                winnersBits = winnersBits | ZERO_VOTES_BIT;
            }
            if (localOneVotesCount == localTwoVotesCount) {
                winnersBits = winnersBits | TWO_VOTES_BIT;
            }
        } else {
            winnersBits = TWO_VOTES_BIT;
            if (localTwoVotesCount == localZeroVotesCount) {
                winnersBits = winnersBits | ZERO_VOTES_BIT;
            }
            if (localTwoVotesCount == localOneVotesCount) {
                winnersBits = winnersBits | ONE_VOTES_BIT;
            }
        }

        return winnersBits;
    }

//---------------------------------------------------------------------------
//------------------------- External Functions

    /**
     * @dev *Expensive* (requiring lots of gas) optional 
     * @dev     function to call to retrieve the ballot results.
     * @dev Note: Contracts are a backend component of DApps 
     * @dev     and this is included only for presenting a string friendly 
     * @dev     representation of the getWinnersByte() return value.
     * @return The string description of the winning votes.
     */
    function getWinnersDesc() external view returns (string memory) {

        bytes1 winnersBits = getWinnersByte();
        return string(
                abi.encodePacked(
                    winnersBits & ZERO_VOTES_BIT > 0 ? "Zero " : "", 
                    winnersBits & ONE_VOTES_BIT  > 0 ? "One "  : "", 
                    winnersBits & TWO_VOTES_BIT  > 0 ? "Two "  : "" ));
    }

   /**
     * @dev Get the contract's balance.
     * @dev Because of the contract's policy of returning any received funds, 
     * @dev it is expected this function to return 0 but in rare cases
     * @dev when refunding fails.
     * @return the contract's balance.
     */
    function getContractBalance() external view returns (uint) {

        return address(this).balance;

    }

    /**
     * Receive funding. Useful for Oraclize queries.
     */
    function fund() public payable {

        uint amountReceived = msg.value;
        emit Received_Funds(msg.sender, amountReceived);
    }

    /**
     * @dev The Contract fallback function for receiving funds.
     * @dev Funding is useful for the Oraclize events.
     * @dev Emits event to signal
     * @dev     Reception of funds
     * @return None but emits Received_Funds
     */
    function() external	payable	onlyValidFallbackCalls {

        fund();
        
    }
}