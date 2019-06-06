var votingContract = artifacts.require("Voting");

module.exports = function(deployer, network, accounts) {

    //
    // Deploy the Voting contract
    // Check out the Voting constructor for details relating to these args:
    //
    deployer.deploy(votingContract,

        //
        // Max loop iterations
        //
        1000,

        //
        // Max Voters
        //
        10000,

        //------ ************** Replace OAR ***************** --------------------
        // Replace with ethereum bridge
        //------ ************** Replace OAR ***************** --------------------
        "0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475",

        //
        // Relative Dealy: [Days] before next query to Oraclize
        // 60 Days
        //
        60,

        //
        // Pass in a few authorized voters
        //
        [accounts[0], accounts[1], accounts[2], accounts[3]],
        // Pass in a few owners
        [accounts[0], accounts[1], accounts[2], accounts[3]], {
            from: accounts[9],
            gas: 999999999,
            value: 500000000000000000
        }
    );
};