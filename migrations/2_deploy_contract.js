const Beth = artifacts.require("Beth");

module.exports = (deployer, network, accounts) => {
  deployer.deploy(Beth, 1, 1, 1).then(function () {
    return deployer.deploy(Beth);
  });
};
