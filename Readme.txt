-----------------------------------
Release notes for submission 3:
 * Gregor's feedback addressed. Thx.
 *  Vonting Enums removed.
 *  Voting events collapsed to one.
 *  Require(s) changed to modifiers.
 *  Standardized modifier strings to eliminate typo issues in require exceptions.
 *  Reduce constants favoring rutntime construction parameters.
 * ManyOwners, Wa contracts are inherited rather than being included as runtime singletons.
 * Turns out inheritance simplifies and reduces boilerplate code as it is composing
 * at the source code level and launching 1 contract at runtime.
--------------------------------------

Installation steps:
    truffle unbox UtkarshGupta-CS/truffle-security

# gui...don't know if ganache-cli uses the same port
    install ganache
    launch ganache

# install ethereum-bridge
    mkdir mario 
    cd mario
    mkdir ethereum-bridge
    cd ethereum-bridge
    git clone https://github.com/oraclize/ethereum-bridge
    npm install
    ethereum-bridge.cmd -a 9 -H 127.0.0.1 -p7545 --dev 
    # note the address in OAR = OraclizeAddrResolverI(<address>);
    # use that address to replace mine in 
    #   2_initial_migration.js of 0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475
    #   TestVoting.sol
    
contracts/Voting.sol is the main contract for Parts I, II.
contracts/ManyOwners.sol is a supplemental contract for Part II.
contracts/Wa.sol the Oraclize contract
test/TestVoting.sol is the test contract for Part II.
    6 Tests have been implemented one of which is introduced after
    last minute issue was identified.
migrations/2_initial_migration.js Very important to set up the contract.
truffle.js is the configuration to bind truffle console to ganache.

Briefly, it implements 
    verifyVoter upon construction or later on with the api.
    Vote function, 
    multiple owners in a separate contract upon construction and later on-demand. 
    Truffle tests.
    Presenting the voting results in an optimal bytes1 value and a more expensive string description.
    Querying extensively till the next President is Mario

It has been tested extensively.
    Oraclize has also been tested in a separate project with Javascript tests.
    Example commands:
        let a = await web3.eth.getAccounts()
        let v = await Voting.deployed()
        let r = await v.addVoter(accounts[1])
        v.vote(1, {from: accounts[1]})
 
Also it has ran successfully in Remix to heed its warnings.    
    
    

    