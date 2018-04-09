# Smart contract

It uses two smart contracts:
`SubscriptionStore.sol`
`SubscriptionManager.sol`
so that, while the store is immutable, it is possible to update the logic in the manager, authorizing the new manager to use the store (since both are Authorizable).

To install everything you should clone recursively the repo to download also the two submodules.

After you need to run
```
npi i && truffle install
(cd ethereum-bridge && npm i)
```
At this point, run the test server 
```
(cd smartContract && npm run testServer)
```
in a terminal. In a second termina run the oraclize bridge
```
(cd smartContract && npm run bridge)
```
and finally, in other terminal, you can test it with
```
(cd smartContract && truffle test)
```
The endPoint is set as a variable in `SubscriptionManager.sol` so that it can be update.

The endPoint should allow a call like this

```endPoint/:txId/:costInWei/:tier/:address```

For reason related to how Solidity handle dynamic mappings, the tier is actually a `uint8`. `0` is montly, `1` is yearly.

For similar reason, and to reduce gas usage, the txId cannot be a `string`, but has to be a `uint`.

It is important to check everything, included the `tier` because the smart contract has no way to know if what the sender declares is true or not, and the user can edit the transaction in Metamask and change, for example, the `tier` to `1` (`yearly`), if there is no control.

During the tests, the rpc server is launched with `ganache-cli --mnemonic toktvpass`. Fixing the mnemonic guarantees that Ganache generates every time the same accounts. In our case, the good subscriber is `accounts[8]`, the bad one is `accounts[7]`, etc.

A consideration about the result of the api call.

Right now the api returns 
```
{
"result": true
}
```

This is elegant, but not good for the contract. In fact it requires more gas. If the api returns just the the text `true`, we can call Oraclize this way
```
bytes32 oraclizeID = oraclize_query(
      "URL",
      strConcat(
        endPoint,
        uint2str(_txId),
        "/",
        uint2str(msg.value),
        strConcat("/", uint2str(uint(_tier)), "/0x", addressToString(msg.sender))),
      _gasLimit
    );
```
performing two string concatenations using the Oraclize function `strConcat`.

Though, if the result is a json, we have to call what is right now in this PR
```
bytes32 oraclizeID = oraclize_query(
      "URL",
      strConcat(
        strConcat("json(", endPoint, uint2str(_txId), "/", uint2str(msg.value)),
        strConcat("/", uint2str(uint(_tier)), "/0x", addressToString(msg.sender), ").result")
      ),
      _gasLimit
    );
```
which is more expensive because we need to concatenate many more strings and call three times `strConcat` (since it does not accept more than 5 parameters).

I suggest that the api returns just a text with simply `true`.


