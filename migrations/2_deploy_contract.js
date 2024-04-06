const Beth = artifacts.require("Beth");

module.exports = (deployer, network, accounts) => {
    deployer.deploy(Beth).then(function() {
        return deployer.deploy(Beth);
    });
};