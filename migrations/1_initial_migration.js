var Migrations = artifacts.require("Migrations");

module.exports = function(deployer) {

    // Deploy the Migrations contract
    deployer.deploy(Migrations);
};