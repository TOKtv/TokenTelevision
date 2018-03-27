const assertRevert = require('./helpers/assertRevert')
const logEvent = require('./helpers/logEvent')
const log = require('./helpers/log')

const sleep = require('sleep')
const bigInt = require("big-integer")

const SubscriptionStore = artifacts.require('./SubscriptionStore.sol')
const SubscriptionManager = artifacts.require('./mocks/SubscriptionManagerMock.sol')

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

  before(async () => {
    store = await SubscriptionStore.new()
    manager = await SubscriptionManager.new()
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
      gas: 350000
    })

    let ok = false

    for (let i = 0; i < 15; i++) {
      console.log('Waiting for result')
      sleep.sleep(1)
      let uid = await store.getLastTransactionId(good.address)
      if (uid == good.txId) {
        ok = true
        break
      }
    }
    assert.isTrue(ok)

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
      let uid = await store.getLastTransactionId(bad.address)
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

})
