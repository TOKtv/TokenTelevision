const assertRevert = require('./helpers/assertRevert')
const logEvent = require('./helpers/logEvent')
const log = require('./helpers/log')

const sleep = require('sleep')
const bigInt = require("big-integer")

const SubscriptionStore = artifacts.require('./SubscriptionStore.sol')
const SubscriptionManager = artifacts.require('./SubscriptionManager.sol')

const fixtures = require('./fixtures/index')

function val(x) {
  return x.valueOf()
}

contract('SubscriptionManager', accounts => {

  // return

  let manager
  let store

  const owner = accounts[0]
  const authorized = accounts[1]
  const beneficiary = accounts[2]
  const subscriber = accounts[8]
  const fakeSubscriber = accounts[7]
  const subscriberWithErrors = accounts[6]
  const developer = accounts[5]
  const customerService = accounts[4]

  let endPoint

  before(async () => {
    store = await SubscriptionStore.new()
    manager = await SubscriptionManager.new()
    endPoint = (await manager.endPoint()).valueOf()
  })

  it('should authorize the manager to handle the store', async () => {
    await store.authorize(manager.address, 1)
    assert.isTrue(await store.authorized(manager.address) == 1)
  })

  it('should revert trying to verify a transaction before setting the store', async () => {

    const gasPrice = 1e9

    await assertRevert(
    manager.verifySubscription(
    1000,
    0,
    gasPrice,
    12e4,
    {
      from: subscriber,
      value: gasPrice * 120000,
      gas: 300000 // 171897 on Ropsten
    }))

  })

  it('should set the store in the manager', async () => {
    await manager.setStore(store.address)
    assert.isTrue(await manager.storeSet())
  })

  it('should authorized developer and customerService the handle specific functions', async () => {
    await manager.authorize(developer, 5)
    await manager.authorize(customerService, 6)
    assert.equal(await manager.authorized(developer), 5)
    assert.equal(await manager.authorized(customerService), 6)
  })

  it('should change the endPoint', async () => {
    const newEndPoint = "https://vp-api-crypto-dev.tok.tv/v1/notify-payment/"
    await manager.changeEndPoint(newEndPoint, {from: developer})
    assert.equal(await manager.endPoint(), newEndPoint)
  })

  it('should reverse the endPoint', async () => {
    await manager.changeEndPoint(endPoint, {from: developer})
    assert.equal(await manager.endPoint(), endPoint)
  })


  // the following two test can be improved logging the event.
  // But since I have little time today, I am going with a
  // brute force approach.

  it('should call Oraclize, verify the txId and set the new subscription', async () => {

    const good = fixtures.good

    const gasPrice = 1e9
    const gasLimit = 16e4

    await manager.verifySubscription(
    good.txId,
    good.tier, // monthly subscription
    gasPrice,
    gasLimit,
    {
      from: good.address, // is subscriber
      value: good.value,
      gas: 300000
    })

    let verified = false

    for (let i = 0; i < 15; i++) {
      console.log('Waiting for result')
      sleep.sleep(1)
      let uid = await store.getLastTransactionId(good.address)
      if (uid == good.txId) {
        verified = true
        break
      }
    }
    assert.isTrue(verified)

  })

  it('should call Oraclize, verify the txId and refuse the new subscription', async () => {

    const bad = fixtures.bad

    const gasPrice = 1e9
    const gasLimit = 16e4

    await manager.verifySubscription(
        bad.txId,
        bad.tier, // monthly subscription
        gasPrice,
        gasLimit,
        {
          from: bad.address, // is subscriber
          value: bad.value,
          gas: 350000
        })

    let ok = false

    for (let i = 0; i < 15; i++) {
      console.log('Waiting for result')
      sleep.sleep(1)
      let uid = await store.getLastTransactionId(fakeSubscriber)
      if (uid == bad.txId) {
        ok = true
        break
      }
    }
    assert.isFalse(ok)
  })

  it('should revert trying to withdraw before setting the beneficiary', async () => {
    await assertRevert(manager.withdrawEther());
  })

  it('should set the beneficiary', async () => {
    await manager.setBeneficiary(beneficiary);
    assert.equal(await manager.beneficiary(), beneficiary)
  })

  it('should withdraw the contract balance', async () => {

    const contractBalanceBefore = bigInt(val(await web3.eth.getBalance(manager.address)))
    const beneficiaryBalanceBefore = bigInt(val(await web3.eth.getBalance(beneficiary)))

    await manager.withdrawEther();

    contractBalance = val(await web3.eth.getBalance(manager.address))
    assert.equal(contractBalance, 0)
    const balance = bigInt(val(await web3.eth.getBalance(beneficiary)))
    assert.equal(balance.compare(beneficiaryBalanceBefore.add(contractBalanceBefore)), 0)
  })

  it('should force a subscription for a subscriber who did not complete the process due to errors', async () => {
    const withErrors = fixtures.withErrors
    await manager.setSubscription(withErrors.txId, withErrors.tier, withErrors.address, {from: customerService})
    assert.equal(await store.getLastTransactionId(subscriberWithErrors), withErrors.txId)
  })

})
