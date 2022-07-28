const Event = artifacts.require("EventStaking");

module.exports = function (deployer) {
  deployer.deploy(Event);
};
