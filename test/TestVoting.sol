// solium-disable linebreak-style
pragma solidity ^0.5;

/**
 *
 * Note replace below the OAR value from your Ethereum Bridge launch.
 *
 * Test Voting Contract resulting in the following:
 *
 *  TestVoting
 *      √ testDefaultVoteResults (94ms)
 *      √ testVerifiedVoterBecomesUnverified (234ms)
 *      √ testMultipleVotesResults (255ms)
 *      √ testMultipleOwners (141ms)
 *      √ testVerifyUnverifedVoter (109ms)
 *      √ testFirstNameParsing (239ms)
 *
 *
 *  6 passing (27s) 
 */

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract TestVoting {

    //
    // Empty address so this contract's (test) address becomes the single owner
    // No verified voter to start with.
    //
    address[] addresses;
    address contractAddr = address(this);
    Voting v = new Voting(1000, 10000, 

        //------ ************** Replace OAR ***************** --------------------
        // Replace with ethereum bridge
        //------ ************** Replace OAR ***************** --------------------
        0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475,

        // Days delay before next query.
        60,
    
        addresses, addresses);
    
    /**
     * Default winning voting result with 0 votes for all.
     */
    function testDefaultVoteResults() public {
        bytes1 defaultAllThreeVotesWin = 0x07;
        Assert.equal(v.getWinnersByte(), defaultAllThreeVotesWin, "All three vote types (0, 1, 2) win with 0 votes each.");
    }

    /**
     * Test whether a verified voter turns unverified after each vote.
     */
    function testVerifiedVoterBecomesUnverified() public {

        Assert.equal(v.isVoterVerified(contractAddr), false, "This contract is not a verified voter.");
        v.verifyVoter(contractAddr);
        v.vote(0);
        // Voter can't vote again
        Assert.equal(v.isVoterVerified(contractAddr), false, "Voter should now be unverified after last vote");
        Assert.equal(v.getWinnersByte(), bytes1(0x01), "Expected winning votes are ZERO: 0x01.");
    }
    
    /**
     *
     * Test how each cat vote changes the winning result progressively.
     * Note this test runs after previous with Zero being 1 ahead.
     *
     */
    function testMultipleVotesResults() public {

        // Make this contract (test) a verified voter
        v.verifyVoter(contractAddr);
        v.vote(1);
        Assert.equal(v.getWinnersByte(), bytes1(0x03), "Expected winning votes are ZERO & ONE: 0x03.");

        v.verifyVoter(contractAddr);
        v.vote(2);
        Assert.equal(v.getWinnersByte(), bytes1(0x07), "Expected winning votes are ZERO & ONE & TWO : 0x07.");

        v.verifyVoter(contractAddr);
        v.vote(1);
        Assert.equal(v.getWinnersByte(), bytes1(0x02), "Expected winning vote is ONE : 0x02.");
    }

    /**
     * Test support for 2 owners
     */
    function testMultipleOwners() public {

        Assert.equal(v.isOwner(contractAddr), true, "This contract address is an owner.");

        address newOwnerToBe = address(0x00Bb86893B183c1fD3A40a2C74D12EE05C35944B);

        Assert.equal(v.isOwner(newOwnerToBe), false, "New address is not an owner.");

        // Add new addres as 2nd owner
        v.addOwner(newOwnerToBe);

        Assert.equal(v.isOwner(contractAddr) && v.isOwner(newOwnerToBe), true, "Multiple owners are now active.");
    }
    
    /**
     * Test unverified voter to verified.
     */
    function testVerifyUnverifedVoter() public {

        address newVoterToBe = address(0x00Bb86893B183c1fD3A40a2C74D12EE05C35944B);
        Assert.equal(v.isVoterVerified(newVoterToBe), false, "The new voter expected not to be verified.");

        // Make new address a verified voter
        v.verifyVoter(newVoterToBe);

        Assert.equal(v.isVoterVerified(newVoterToBe), true, "The new voter should now be a verified voter.");
    }

    /**
     * Test unverified voter to verified.
     */
    function testFirstNameParsing() public {

        Assert.equal(v.getIsMarioPrez("Nicos Anastasiades"), false, "Current prez's first name is not mario");
        Assert.equal(v.getIsMarioPrez("mario Anastasiades"), true, "Yes it's mario");
        Assert.equal(v.getIsMarioPrez("   mArIo Nicos Anastasiades"), true, "Yes first out of 3 names is mario");
        Assert.equal(v.getIsMarioPrez("mArIo"), true, "Yes first and only one is mario");
        Assert.equal(v.getIsMarioPrez("mar io"), false, "mar io is not acceptable");
    }
}