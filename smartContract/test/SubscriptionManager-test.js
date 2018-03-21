const assertRevert = require('./helpers/assertRevert')
const logEvent = require('./helpers/logEvent')

const sleep = require('sleep')

const SubscriptionStore = artifacts.require('./SubscriptionStore.sol')
const SubscriptionManager = artifacts.require('./SubscriptionManager.sol')

const fixtures = require('./fixtures/index')

contract('SubscriptionManager', accounts => {

  // return

  let manager
  let store

  const owner = accounts[0]
  const authorized = accounts[1]
  const subscriber = accounts[2]

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
      gas: 200000 // 171897 on Ropsten
    }))

  })

  it('should set the store in the manager', async () => {
    await manager.setStore(store.address)
    assert.isTrue(await manager.storeSet())
  })

  return;

  // will test this as soon as we have a test api

  it('should call Oraclize, verify the txId and set the new subscription', async () => {

    const gasPrice = 1e9
    const gasLimit = 12e4

    await manager.verifySubscription(
    1000,
    0, // monthly subscription
    gasPrice,
    gasLimit,
    {
      from: subscriber,
      value: gasPrice * gasLimit,
      gas: 200000 // 171897 on testnet
    })

    let ok = false

    for (let i = 0; i < 30; i++) {
      console.log('Waiting for result')
      sleep.sleep(1)
      let uid = await store.getLastTransactionId(subscriber)
      if (uid == 1000) {
        ok = true
        break
      }
    }

    assert.isTrue(ok)

  })

})
