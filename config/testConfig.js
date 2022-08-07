
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0xe8e2352988c97a32fb0405486a29b48cf7942e42",
        "0xb7d0b759ed0c126900ece1b573163c8c64bfc642",
        "0x5941ecad72b811c98ea3f261ecc683e7c4b81773",
        "0xc871f01b78ec39c02f0ad3fe592e4ec63d912596",
        "0xd73247c74487e1db739b1238d836e5866d5ca05a",
        "0x31672ab3d817b2a11231f4745e941cf4ec21025f",
        "0x0f6e13bdfa0a21d2e2205703a5de5ad55aaee157",
        "0x990ba7f4149679b7a200d2887ff07358960ab7f7",
        "0x445b33973a8d1931787c7c7711dea6cbc9ed58b9",
        "0x4d545172160a896f36ba17c83f26a4d5d0ac3396"
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new();
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);

    
    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};