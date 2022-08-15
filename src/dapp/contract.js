import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }
    registerAirline(airline, callback) {
        let self = this;
        self.flightSuretyApp.methods
        .registerAirline(airline)
        .send({from: this.account})
            .then(console.log);
        
    }

    fundAirline(amount, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .fundAirline()
            .send({from: this.account, value: this.web3.utils.toWei(amount, 'ether')})
                .then(console.log);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
    registerAirline(airlineName, airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .registerAirline(airlineName, airlineAddress)
            .send({ from: self.owner, gas: 9999999 }, callback);
    }
    isAirlineRegistered(airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isAirlineRegistered(airlineAddress)
            .call({ from: self.owner }, callback);
    }

    isAirlineFunded(airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isAirlineFunded(airlineAddress)
            .call({ from: self.owner }, callback);
    }
    voteForAirline(airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .voteForAirline(airlineAddress)
            .send({ from: self.owner, gas: 9999999 }, callback);
    }

    isAirlinePending(airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isAirlinePending(airlineAddress)
            .call({ from: self.owner }, callback);
    }

    buy(flightName, airlineAddress, timestamp, amount, callback) {
        let self = this;
        const insuredAmount = this.web3.utils.toWei(amount, 'ether');
        self.flightSuretyApp.methods
            .buy(flightName, airlineAddress, timestamp)
            .send({ from: self.owner, gas: 999999, value: insuredAmount }, callback);
    }
    getPassengerCredit(passangerAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .getPassengerCredit(passangerAddress)
            .call({ from: self.owner }, callback);
    }

    withdrawCredit(pessangerAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .withdrawCredit(pessangerAddress)
            .send({ from: self.owner }, (error, result) => {
                callback(error, result);
            });
    }
}