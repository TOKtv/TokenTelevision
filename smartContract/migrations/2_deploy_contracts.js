var SubscriptionStore = artifacts.require("./SubscriptionStore")
var SubscriptionManager = artifacts.require("./SubscriptionManager")

module.exports = function(deployer) {
  deployer.deploy(SubscriptionStore)
  deployer.deploy(SubscriptionManager)
}
