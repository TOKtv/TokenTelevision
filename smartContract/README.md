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
in a terminal. In a second terminal run the oraclize bridge
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

## How to deploy to Ropsten

### 1. Create a test wallet

The easiest way is to run `ganache-cli`. It will use a random mnemonic and use that to generate the wallet.   
Save securely the mnemonic, the address of the accounts[0] and its private key. That is your new test wallet.  
Create a text file `testnet.env` and put it in the folder that contains this repo (so that it is not saved on Github).
In the file, white something like:

```text
export MNEMONIC="base guitar george mind life tree combat otto war safe beast mogul"
```

### 2. Open an API account on Infura

Connect to https://infura.io  
Click on get started for free  
Follow the instruction and generate a unique API identifier. Save the indentifier in the file `infura.env` like this

```
export INFURA_KEY="ABtS63rg7cbunycXMg"
```

### 3. Build the contracts

Run `truffle migrate`
This will create a folder `build` containing the metadata of the contracts.
If you open `build/contracts/SubscriptionManager.sol` you will see that the second parameter is `abi`.

### 4. Send some ether to the testnet wallet

On Metamask, connect to Ropsten and from any account that has some ether send 0.4 ether (or more) to the testnet wallet. Those will be used during the deployment.

### 5. Deploy the contract

As soon as the testnet wallet has received the ether you can deploy the smart contract to the testnet.
To deploy run `npm run deployToRopsten`. It expects to find the the files `testnet.env` and `infura.env` in the folder which contains the repo. If you prefer a different location, modify the script in `package.json`.
After running the script you will see that it is deploying. At the end of the process it should show you the address where the two contracts have been deployed. Save the addresses.

### 6. Set up the Store

Open [MyEtherWallet](https://myetherwallet.com) and create a new wallet importing the private key of the testnet wallet created before.
Move the network to Ropsten (Infura).
Click on `Contracts`. In the form copy the address where the Store has been published (see above) and the abi of SubscriptionStore.sol (in `build/contracts`).
MEW loads the contracts and show the functions. Select `authorize` and authorize the address of SubscriptioManager setting the level to 1. It will ask which wallet to use, select the testnet wallet (which is the owner of the contract, since it is the wallet used to publish it).

### 7. Set up the manager

Open MEW in another tab and repeat the process but using address and abi of SubscriptionManager.
Execute `setStore` passing the address of the Store as parameter.

## In the DApp

You don't need to access directly the store, so you just need to connect to the SubscriptioManager. Set its abi and its address in the javascript file. Consider that Ropsten network id is 3 (4 is Rinkeby's id).
