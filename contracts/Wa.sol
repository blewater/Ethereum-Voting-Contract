// solium-disable linebreak-style
pragma solidity ^0.5.0;

import "./oraclizeAPI.sol";

/**
 *
 * @dev Interface with Oraclize in 5.0 fashion
 * @dev Main purpose to set bool storage IsMarioPrez as to whether the current president's name starts with mario :)
 *
 *  Example execution result
 * 
 *  [2019-02-22T01:21:16.781Z] INFO sending __callback tx...
 *          {
 *      "contract_myid": "0xaf9c9029a46cf93613729ddb9fa22c04ef0856e051ea96f6e127baebfd06c645",
 *      "contract_address": "0xddcf4eb16a999b436161ad137f7031d11675aa9d"
 *  }
 *  [2019-02-22T01:21:22.060Z] INFO contract 0xddcf4eb16a999b436161ad137f7031d11675aa9d __callback tx sent, transaction hash: 0x022ad5a25aa815403acb6c4a43d29901dd07627f77370567043128c5468aeed2
 *          {
 *      "myid": "0xaf9c9029a46cf93613729ddb9fa22c04ef0856e051ea96f6e127baebfd06c645",
 *      "result": "Nicos Anastasiades",
 *      "proof": null,
 *      "proof_type": "0x00",
 *      "contract_address": "0xddcf4eb16a999b436161ad137f7031d11675aa9d",
 *      "gas_limit": 1000000,
 *      "gas_price": 1000000000
 *  }
 *  ------------------------------------------------------------------------------
 *  Note the next pending query 60 days from now that's sitting for fullfilment...
 *
 *  [2019-02-23T02:00:54.902Z] INFO new HTTP query created, id: 3d4e1a72cd9d19ffb7fe6266d93623db8e817f52f1f7a3e927c094faf17b7b4f
 *  [2019-02-23T02:00:54.904Z] INFO checking HTTP query 3d4e1a72cd9d19ffb7fe6266d93623db8e817f52f1f7a3e927c094faf17b7b4f status on Wed Apr 24 2019 05:00:53 GMT+0300 (Eastern European Summer Time)
 */
contract Wa is usingOraclize {

//--------------------------------------------------------
//------------------- Storage Declarations

    //
    // When true it ends voting.
    //
    bool public IsMarioPrez = false;

    //
    // President is declared in storage for testing purposes
    // Not needed for application flow
    // 
    string public President = "";
    
    //
    // Check whether response matches request id
    //
    mapping(bytes32=>bool) ValidQryIds;

    //
    // Terse WolframAlpha request with my app id
    //
    string constant wolframCyprusPres = "https://api.wolframalpha.com/v1/result?i=Cyprus+president%3F&appid=7YX4VR-HYV3XJ9QTR";

    //
    // daysDelayForNextOraclizeQuery
    //
    uint public DaysInSecondsDelayForNextOraclizeQuery = 60 * 24 * 3600;
//--------------------------------------------------------------------------------
//------------------------ Events Declarations

    event LogNewOraclizeQuery(string description, uint secondsToDelay);
    event LogNewPrezResult(string prezRes);

//--------------------------------------------------------------------------------
//------------------------ Modifier Declarations

    //
    // Oraclize response id in __callback matching the request id.
    //
    modifier onlyValidResponseOraIds(bytes32 respId) {
        require (ValidQryIds[respId], 
        "ORA1: Not valid response Id to query.");
        _;
    }

    //
    // __callback check for matching response address to request
    //
    modifier onlyValidOraAddress() {
        require(msg.sender == oraclize_cbAddress(), 
        "ORA2: cbAddress not matching msg.sender.");
        _;
    }

//------------------------------------------------------------------------------
//--------------------------- Public Functions

    /**
     * @dev Setup oraclize and ask the current president.
     * @param oraclizeResAddr OAR address related to Ethereum bridge.
     * @param daysDelayForNextOraclizeQuery delay in Days before next query.
     */
    function setupOraclize(
        address oraclizeResAddr,
        uint daysDelayForNextOraclizeQuery) internal {

        //
        // Replace the following with the value from the ethereum-bridge launch
        // ethereum-bridge.cmd -a 9 -H 127.0.0.1:7545 --dev
        //
        OAR = OraclizeAddrResolverI(oraclizeResAddr);

        //
        // Days before next query.
        //
        DaysInSecondsDelayForNextOraclizeQuery = daysDelayForNextOraclizeQuery * 24 * 3600;

        //
        // Instead of the default 20 GWei opt in for a friendlier gas price: 2 Gwei
        //
        oraclize_setCustomGasPrice(2000000000);
        
        //
        // Update on contract creation...
        //
        queryWolframAlpha(0);

    }

    /**
     * Call query again if first name != mario
     * @param queryAgain T/F whether to query for a response in 59 days.
     */
    function CallUpdateAgainIfNecessary(bool queryAgain) internal {

        if (queryAgain) {
            queryWolframAlpha(DaysInSecondsDelayForNextOraclizeQuery);
        }
    }

    /**
     * Called by oraclize itself to answer the pending query.
     * Hard to troubleshoot if it appears that it never enters here your 
     * after you see the query response in ethereum bridge.
     * Two reasons I found for this:
     * 1. Wrong function signature if using proof authentication
     * 
     * 2. These queries are gas guzzles especially with the contained recursive query call
     * and if it spends all available contract balance
     * -- or --
     * reaches a custom API gas limit during the execution of this, it rolls back and appears 
     * like it never entered this... 
     *
     */
    function __callback(bytes32 respId, string memory result) public 
        onlyValidResponseOraIds(respId)
        onlyValidOraAddress {

        bool isMarioPrez = getIsMarioPrez(result);
        // Not needed other than for testing
        President = result;

        IsMarioPrez = isMarioPrez;

        emit LogNewPrezResult(result);

        delete ValidQryIds[respId];

        //
        // Not elegant but enter in a 2-month loop of constant queries
        // Till there's a positive response
        // Check next update max time from now: two months.
        //
        CallUpdateAgainIfNecessary(!IsMarioPrez);
    }

    /**
     * @dev Query wolfram alpha with an estimated gas for lower costs.
     * @dev Side effect: __callback is called.
     * @dev authenticity proof is not used because it comes back empty.
     * @dev other authenticity mechanisms are used i.e. queryId, cbAddress (see __callback)
     */
    function queryWolframAlpha(uint secondsToDelay) public payable {
        
        emit LogNewOraclizeQuery("New Cypriot Prez Request:", secondsToDelay);

        //
        // Had touble to squeze the gas limit here to 50k instead of using the default 200k 
        // as it is suggested by afficionados. 
        // Note each query is prepaid and the difference due to the callback nature
        // is refunded to Oraclize.
        // Before launching to a live network, a plethora of testing would
        // determine the optimal price for each query and subsequent recursive one.
        //
        bytes32 queryId = oraclize_query(secondsToDelay, "URL", wolframCyprusPres);
        ValidQryIds[queryId] = true;
    }

    /**
     * @dev Detects whether "maRio" in any small/caps combination is the first substring within the input parameter.
     * @dev Tolerates initial spaces e.g. "      Mario" or " mario" or "mArio"
     * @param fullName The returned oraclize name string to search for the given first name.
     * Note as of this writing it looks like this: "Nicos Anastasiades"
     * @return True/False Whether mario is contained as a substring at index 0 or few spaces later.
     */
    function getIsMarioPrez(string memory fullName) public pure returns (bool) {
        bytes memory fullNameBytes = bytes(fullName);
        bytes memory soughtAfterCaps = bytes("MARIO");
        bytes memory soughtAfterSmall = bytes("mario");

        uint8 fni = 0;
        uint8 spaces = 0;
        bytes1 space = bytes1(" ");
        for(uint8 i = 0; i < fullNameBytes.length && i < 256; ) {
            if (fullNameBytes[i] == space && i == spaces) {
                
                // Eat up preceeding white spaces.
                i++;
                spaces++;
                
            } else if (fni < 4 && (fullNameBytes[i] == soughtAfterCaps[fni] || fullNameBytes[i] == soughtAfterSmall[fni])) {
                
                // Matching any of [Mari]
                i++;
                fni++;

            } else if (fni == 4 && (fullNameBytes[i] == soughtAfterCaps[fni] || fullNameBytes[i] == soughtAfterSmall[fni])) {
                
                // final o in mario
                return true;
                
            } else if (fni > 0 && (fullNameBytes[i] != soughtAfterCaps[fni] && fullNameBytes[i] != soughtAfterSmall[fni])) {
                
                // Detected unrelated character within mario e.g. Mar io
                return false;
                
            } else {
                
                // Any non-space irrelevant byte...
                return false;
            }
        }

        return false;
    }
}