pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    struct Airline {
        string name;
        address airlineAddress;
        bool isFunded;
        uint256 votes;
    }
    
    mapping(address => Airline) private registeredAirlines;
    mapping(address => Airline) private pendingAirlines;

    struct Passenger{
        address passengerAddress;
        mapping (bytes32 => uint256) insuredFlights;
        uint256 credit;
    }

    mapping(address => Passenger) private passengers;
    address[] public passengerAddresses;

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    uint256  registeredAirlineCounter = 0;
    uint256 totalFunds = 0;

    mapping(address => bool) private authorizedAppContracts;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        passengerAddresses = new address[](0);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

   function isAirlineRegistered
                            (
                                address airline
                            )
                            external
                            view
                            returns(bool)
    {
        return registeredAirlines[airline].airlineAddress != address(0);
    }

    function isAirlinePending
                            (
                                address airline
                            )
                            external
                            view
                            returns(bool)
    {
        return pendingAirlines[airline].airlineAddress != address(0);
    }
    function getRegisteredAirlineCounter()
                            external
                            view
                            returns(uint256)
    {
        return registeredAirlineCounter;
    }

    function isAirlineFunded
                            (
                                address airline
                            )
                            external
                            view
                            returns(bool) 
    {
        return registeredAirlines[airline].isFunded;
    }

    function getPassengerCredit
                            (
                                address insuredPassenger
                            )
                            external
                            view
                            returns(uint256)
    {
        return passengers[insuredPassenger].credit;
    }
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                string memory name,
                                address airlineAddress
                            )
                            public
                            requireIsOperational
    {
        registeredAirlines[airlineAddress] = Airline({
            name:name,
            airlineAddress:airlineAddress,
            isFunded:false,
            votes:0
        });

         registeredAirlineCounter = registeredAirlineCounter.add(1);
    }
    function addPendingAirline
                            (   
                                string calldata name,
                                address airlineAddress
                            )
                            external
                            requireIsOperational
    {
        pendingAirlines[airlineAddress] = Airline({
            name:name,
            airlineAddress:airlineAddress,
            isFunded:false,
            votes:1
        });
    }

    function voteForAirline
                            (
                                address airlineAddress
                            )
                            external
                            requireIsOperational
                            returns (uint256)
    {
        pendingAirlines[airlineAddress].votes = pendingAirlines[airlineAddress].votes.add(1);
        if (pendingAirlines[airlineAddress].votes >= registeredAirlineCounter.div((2))) {
            registerAirline(pendingAirlines[airlineAddress].name, airlineAddress);
            delete pendingAirlines[airlineAddress];
        }
        return pendingAirlines[airlineAddress].votes;
    }

    function fundAirline
                            (
                                address airlineAddress,
                                uint256 amount
                            )
                            external
                            payable
                            requireIsOperational
    {

        registeredAirlines[airlineAddress].isFunded = true;
        totalFunds = totalFunds.add(amount);
    }
   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buyInsurance
                            (        
                                bytes32 flightKey,
                                address passengerAddress,
                                uint256 insuredAmount    
                            )
                            external
                            payable
                            requireIsOperational
    {
        if (passengers[passengerAddress].passengerAddress != address(0)) { // Existing insured passenger
            require(passengers[passengerAddress].insuredFlights[flightKey] == 0);
            
        } else { // New insured passenger
            passengers[passengerAddress] = Passenger({
                passengerAddress: passengerAddress,
                credit: 0
            });
            passengerAddresses.push(passengerAddress);
        }
        passengers[passengerAddress].insuredFlights[flightKey] = insuredAmount;
        totalFunds = totalFunds.add(insuredAmount); 
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    bytes32 flightKey
                                )
                                external
                                requireIsOperational
    {
        for (uint256 i = 0; i < passengerAddresses.length; i++) {
            if(passengers[passengerAddresses[i]].insuredFlights[flightKey] != 0) { // Insured flights
                uint256 payedPrice = passengers[passengerAddresses[i]].insuredFlights[flightKey];
                uint256 savedCredit = passengers[passengerAddresses[i]].credit;
                passengers[passengerAddresses[i]].insuredFlights[flightKey] = 0;
                passengers[passengerAddresses[i]].credit = savedCredit + payedPrice + payedPrice.div(2); // 1.5X the amount they paid
            }
        }
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address payable pass
                            )
                            external
                            payable
                            requireIsOperational
    {
        require(pass == tx.origin, "Contracts not allowed");
        require(passengers[pass].passengerAddress != address(0), "The passenger is not insured");
        require(passengers[pass].credit > 0, "There is not credit pending to be withdrawed for the passenger");
        uint256 credit = passengers[pass].credit;
        require(address(this).balance > credit, "The contract does not have enough funds to pay the credit");
        passengers[pass].credit = 0;
        pass.transfer(credit);
    }
    function authorizeCaller
                            (
                                address appContract
                            )
                            public
    {
        authorizedAppContracts[appContract] = true;
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    */
    
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

