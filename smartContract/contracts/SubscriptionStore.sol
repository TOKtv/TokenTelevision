pragma solidity ^0.4.18;

import 'zeppelin/math/SafeMath.sol';
import '../../authorizable/contracts/Authorizable.sol';

contract SubscriptionStore is Authorizable {

  using SafeMath for uint;

  mapping(uint8 => uint) public tiers;

  struct Subscription {
    uint lastTransactionId;
    uint expirationTimestamp;
  }

  mapping(address => Subscription) public subscription;

  // events

  event newSubscription(address _address, uint _txId, bool _result);

  function SubscriptionStore() public {
    tiers[0] = 30 days;
    tiers[1] = 1 years;
  }

  function setTier(uint8 _tier, uint _duration) public onlyAuthorized {
    require(tiers[_tier] == 0);
    // There is no requirement for the _duration because
    // setting the _duration to 0 is equivalent to remove the tier

    tiers[_tier] = _duration;
  }

  function setSubscription(address _address, uint _txId, uint8 _tier) public onlyAuthorized {
    require(_address != address(0));
    if (tiers[_tier] != 0) {
      uint expirationDate;
      if (subscription[_address].expirationTimestamp != 0) {
        // subscription renew/extension
        expirationDate = subscription[_address].expirationTimestamp.add(tiers[_tier]);
      } else {
        expirationDate = now + tiers[_tier];
      }
      subscription[_address] = Subscription(_txId, expirationDate);

      newSubscription(_address, _txId, true);
    } else {
      // this avoid to revert, so that we have a listenable event if the tier does not exist
      newSubscription(_address, _txId, false);
    }
  }

  function getLastTransactionId(address _address) public constant returns (uint){
    return subscription[_address].lastTransactionId;
  }

  function getExpirationTimestamp(address _address) public constant returns (uint){
    return subscription[_address].expirationTimestamp;
  }

}