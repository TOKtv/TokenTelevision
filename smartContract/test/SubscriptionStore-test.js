const sleep = require('sleep')

const assertRevert = require('./helpers/assertRevert')
const log = require('./helpers/log')

const SubscriptionStore = artifacts.require('./SubscriptionStore.sol')

function now() {
  return Math.round(Date.now() / 1000)
}

function equalBySecond(ts1, ts2) {
  // console.log(ts1.valueOf(), ts2)
  let diff = Math.abs(ts1.valueOf() - ts2)
  return diff <= 1;
}

contract('SubscriptionStore', accounts => {

  let store

  const owner = accounts[0]
  const authorized = accounts[1]
  const firstSubscriber = accounts[2]
  const secondSubscriber = accounts[3]

  const oneDay = 24 * 60 * 60;
  const oneMonth = oneDay * 30;
  const oneYear = oneDay * 365;

  before(async () => {
    store = await SubscriptionStore.new()
  })

  it('should revert trying to add a new subscription', async () => {
    await assertRevert(store.setSubscription(firstSubscriber, 1000, 0))
  })

  it('should authorize authorized to handle the data', async () => {
    await store.authorize(authorized, 1)
    assert.equal(await store.authorized(authorized), 1)
  })

  it('should add a new monthly subscription for firstSubscriber', async () => {

    await store.setSubscription(firstSubscriber, 1000, 0, {from: authorized})
    assert.equal(await store.getLastTransactionId(firstSubscriber), 1000)
    assert.isTrue(equalBySecond(await store.getExpirationTimestamp(firstSubscriber), now() + oneMonth))
  })

  it('should extend a subscription of another month for firstSubscriber', async () => {

    await store.setSubscription(firstSubscriber, 1001, 0, {from: authorized})
    assert.equal(await store.getLastTransactionId(firstSubscriber), 1001)
    assert.isTrue(equalBySecond(await store.getExpirationTimestamp(firstSubscriber), now() + 2 * oneMonth))
  })

  it('should add a new yearly subscription for secondSubscriber', async () => {

    await store.setSubscription(secondSubscriber, 1002, 1, {from: authorized})
    assert.equal(await store.getLastTransactionId(secondSubscriber), 1002)
    assert.isTrue(equalBySecond(await store.getExpirationTimestamp(secondSubscriber), now() + oneYear))
  })



})
