pragma solidity ^0.4.18;


import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import 'authorizable/contracts/Authorizable.sol';

import '../../ethereum-api/oraclizeAPI.sol';

import './SubscriptionStore.sol';

contract SubscriptionManager is usingOraclize, Pausable, Authorizable {

  address public beneficiary;

  string public endPoint = "https://api.tok.tv/verify-and-get-tier/";

  SubscriptionStore public store;
  bool public storeSet;

  struct TempData {
    address sender;
    uint txId;
    uint8 tier;
  }

  mapping(bytes32 => TempData) internal __tempData;

  modifier isStoreSet() {
    require(storeSet);
    _;
  }

  event newSubscriptionStarted(address indexed _address, uint _txId);
  event newSubscriptionConfirmed(address indexed _address, uint _txId);
  event newSubscriptionFailed(address indexed _address, uint _txId);

  function setStore(address _address) external onlyOwner {
    require(_address != address(0));
    store = SubscriptionStore(_address);
    require(store.amIAuthorized());
    storeSet = true;
  }

  function changeEndPoint(string _endPoint) external onlyOwnerOrAuthorizedAtLevel(5) {
    // be careful using this, because setting a wrong endPoint would cause any Oraclize failing
    // the end point has to end with a slash, like the default value
    // TODO add requires for that
    endPoint = _endPoint;
  }

  function verifySubscription(uint _txId, uint8 _tier, uint _gasPrice, uint _gasLimit) external isStoreSet payable {

    oraclize_setCustomGasPrice(_gasPrice);
    newSubscriptionStarted(msg.sender, _txId);

    bytes32 oraclizeID = oraclize_query(
      "URL",
      strConcat(
        strConcat("json(", endPoint, uint2str(_txId), "/", uint2str(msg.value)),
        strConcat("/", uint2str(uint(_tier)), "/0x", addressToString(msg.sender), ").result")
      ),
      _gasLimit
    );
    __tempData[oraclizeID] = TempData(msg.sender, _txId, _tier);
  }

  function __callback(bytes32 _oraclizeID, string _result) public {
    require(msg.sender == oraclize_cbAddress());

    TempData memory tempData = __tempData[_oraclizeID];
    if (keccak256(_result) == keccak256('true')) {

      newSubscriptionConfirmed(tempData.sender, tempData.txId);
      store.setSubscription(tempData.sender, tempData.txId, tempData.tier);

    } else {
      newSubscriptionFailed(tempData.sender, tempData.txId);
    }
  }

  function setSubscription(uint _txId, uint8 _tier, address _address) external onlyOwnerOrAuthorizedAtLevel(6) {
    // this is an emergency function called by customer service to fix issues
    store.setSubscription(_address, _txId, _tier);
  }

  function setBeneficiary(address _address) external onlyOwner {
    require(_address != address(0));
    beneficiary = _address;
  }

  function withdrawEther() public onlyOwner {
    require(beneficiary != address(0));
    beneficiary.transfer(this.balance);
  }

  function addressToString(address x) internal pure returns (string) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      byte b = byte(uint8(uint(x) / (2 ** (8 * (19 - i)))));
      byte hi = byte(uint8(b) / 16);
      byte lo = byte(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function char(byte b) internal pure returns (byte c) {
    if (b < 10) return byte(uint8(b) + 0x30);
    else return byte(uint8(b) + 0x57);
  }

}
