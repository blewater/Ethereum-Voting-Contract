# Ethereum Voting Contract implemented in Truffle and Solidity #

_The voting contract has only 3 fixed options to choose from: 0 or 1 or 2. The votes can come only from the addresses that are marked as "verified". Thus, the creator (owner) of the contract must mark all permitted addresses as "verified" before the voting can begin (write a function that would help the creator to mark an address as "verified"). To prevent cheating, each verified account can vote only once - after voting, the address is marked as "unverified" and thus can't vote again, unless the creator (owner) of the contract marks it as "verified" again. Return the winner(s) with the most votes._

- The contract supports more than one creator (accounts with special privileges), defined at the creation time or added later.
- The Truffle package contracts contains Solidity tests.
- The voting ends when the first name of the president of Cyprus is "Mario". Using Wolfram Alpha as the source of truth: https://www.wolframalpha.com/input/?i=president+cyprus.

-----------------------------------
Solidity Implementation Special Notes:
 *  Biased against Voting Enums.
 *  Require(s) changed to modifiers in most cases.
 *  Reduce constants favoring rutntime construction parameters.
 *  ManyOwners, Wa contracts are inherited rather than being included as runtime singletons.
 * Solidity inheritance simplifies and reduces boilerplate code as it is composing at the source code level and presenting a single runtime contract.
--------------------------------------

# Installation steps: #

_Step 0: Clone this repo :)_

### 1. Install Truffle globally ##
    npm install -g truffle
    mkdir voting
    cd voting

### 2. Install a truffle box for security ##
    truffle unbox UtkarshGupta-CS/truffle-security
    cd truffle-security
    npm install

### 3. Install Ganache ###
    install ganache
    launch ganache

### 4. install ethereum-bridge ###
    mkdir ethereum-bridge
    cd ethereum-bridge
    git clone https://github.com/oraclize/ethereum-bridge
    npm install
    ethereum-bridge.cmd -a 9 -H 127.0.0.1 -p7545 --dev 
    # note the address in OAR = OraclizeAddrResolverI(<address>);
    # use that address to replace mine in 
    #   2_initial_migration.js of 0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475
    #   TestVoting.sol

### 5. Run contracts ###
    cd ..
    truffle compile
    truffle migrate
    npm run lint:sol

# Truffle Files Documentation #    
    * contracts/Voting.sol is the main contract.

    * contracts/ManyOwners.sol is a supplemental contract for multiple owner support.
    
    * contracts/Wa.sol the Oraclize contract.

    * test/TestVoting.sol is the test contract.

    * Six Tests have been implemented.

    * migrations/2_initial_migration.js Critical truffle configuration to set up the contract.

    * truffle.js is the configuration to bind truffle console to ganache.

# Main Functions #

    VerifyVoter upon construction or later on with the api.
    Vote function, 
    Multiple owners in a separate contract upon construction and later on-demand. 
    Presenting the voting results in an optimal bytes1 value and a more expensive string description.
    Querying indefinitely and intermittently till the next President is Mario
    Truffle tests.

    Oraclize has been tested in a separate project with Javascript tests.
    Example commands:
        let a = await web3.eth.getAccounts()
        let v = await Voting.deployed()
        let r = await v.addVoter(accounts[1])
        v.vote(1, {from: accounts[1]})
 
    Ran successfully in Remix to heed its linter warnings.

### Truffle Commands ###
Before starting ganache make sure truffle.js contents match your own ganache configuration e.g.
```
    module.exports = {
    networks: {
        development: {
        host: "127.0.0.1",
        port: 7545,
        network_id: "*"
        }
    }
    };
```

    ganache

    truffle console
    compile
    migrate

    let a = await web3.eth.getAccounts()
    let v = await Voting.deployed()
    let r = await v.addVoter(accounts[1])
    v.vote(1, {from: accounts[1]})

    Voting.deployed().then(function(v) { return v.addVoter("0x52dD9Eb3025Cf6Ac3cfe7EEd86D235d46FA2B76D"); });

    t = await v.sendTransaction({from: '0x52dD9Eb3025Cf6Ac3cfe7EEd86D235d46FA2B76D', value: 10000000000000000000})
    
    web3.fromWei((gasEstimate	*	web3.eth.getGasPrice()),	'ether')
