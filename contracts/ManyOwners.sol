// solium-disable linebreak-style
pragma solidity ^0.5.0;

/**
 * Contract ManyOwners encapsulates multiple owner functionality for part 2.
 * of assignment.
 *
 * Release Notes for this contract in Submission 2:
 * Vonting Enum removed.
 * Requires changed to modifiers.
 * Constant strings to eliminate typo issues in require exceptions.
 *
 */
contract ManyOwners {

//---------------------------------------------------
//--------- Storage Declarations    

    uint8 NumberOfOwners = 1; // Counting the constructor 

    mapping (address => bool) Owners;

//---------------------------------------------------------------------
//--------------------------- Events

    event New_Promoted_Owner(address promotedUser);
    event Redudant_Owner_Request(address existingOwner);
    event Received_Funds(address sender, uint amount);
    event Refunded_Funds_Succeeded(address recipient, uint amount);

//--------------------------------------------------------------------------------
//------------------------ Modifier Declarations

    //
    // Limit number of Owners
    //
    uint8 constant MAX_OWNERS = 20;

    modifier onlyMaxNumberOfOwners(uint numberOfOwnersToAdd) {
        require(
            NumberOfOwners + 
            numberOfOwnersToAdd <= MAX_OWNERS, "MREQ1: Not allowing more than 20 Voters.");
        _;
    }

    //
    // Enforce owners only
    //
    modifier onlyOwners() {
        require(isOwner(msg.sender), "MREQ2: Not an Owner.");
        _;
    }

    //
    // Prevent invalid fallback calls.
    //
    modifier onlyValidFallbackCalls() {
        require(msg.data.length == 0, "MREQ3: Invalid fallback call()"); 
        _;
    }

//-------------------------------------------------------------
//------------------- Public functions
    /**
     * @dev Constructor:
     * @dev Set the first owner to allow using this contract.
     * @dev You may add more owners later.
     * @dev See AddOwner, AddOwners() of this contract.
     */
    constructor() public {

        Owners[msg.sender] = true;
    }

    /**
     * @dev Return whether a user is an owner.
     * @param user the candidate owner address.
     * @return True/False: whether a user is an owner.
     */
    function isOwner(address user) public view returns(bool) {

        return Owners[user] == true;

    }

    /**
     * @dev Adds a new owner.
     * @dev Requires sender to be an owner.
     * @dev Note this contract is reused by another and 
     * @dev it requires an explicit owner parameter rather than 
     * @dev the msg.sender to authorize the addition.
     * @param newOwner the address to promote.
     * @return None, but emits 
     *      New_Promoted_Owner 
     *      or 
     *      Redudant_Owner_Request.
     */
    function addOwner(address newOwner) public 
            onlyMaxNumberOfOwners(1) 
            onlyOwners() {

        if ( !isOwner(newOwner) ) {

            NumberOfOwners++;

            Owners[newOwner] = true;

            emit New_Promoted_Owner(newOwner);

        } else {

            emit Redudant_Owner_Request(newOwner);
        }
    }

//---------------------------------------------------
//---------------- External functions

    /**
     * @dev Adds multiple new owners if sender is an owner.
     * @dev Requires sender to be an owner.
     * @dev Note this contract is reused by another and 
     * @dev it requires an explicit owner parameter rather than 
     * @dev the msg.sender to authorize the addition.
     * @param newOwners the address array of users to promote.
     * @return None, but emits 
     *      New_Promoted_Owner 
     *      or 
     *      Redudant_Owner_Request for each addition.
     */
    function addOwners(address[] memory newOwners) public 
            onlyMaxNumberOfOwners(newOwners.length)
            onlyOwners() {

        for (uint8 i = 0; i < newOwners.length; i++) {

            // Reuse function for single owner
            addOwner(newOwners[i]);

        }
    }
}