pragma solidity ^0.4.18;


import '../SubscriptionManager.sol';


contract SubscriptionManagerMock is SubscriptionManager {

  function SubscriptionManagerMock() public {
    endPoint = "https://vp-api-crypto-dev.tok.tv/v1/notify-payment/";
  }

}
