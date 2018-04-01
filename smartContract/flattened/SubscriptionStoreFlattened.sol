pragma solidity ^0.4.18;

// File: zeppelin/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: ../authorizable/contracts/Authorizable.sol

// @title Authorizable
// The Authorizable contract provides authorization control functions.

/*
  The level is a uint <= maxLevel (64 by default)
  
    0 means not authorized
    1..maxLevel means authorized

  Having more levels allows to create hierarchical roles.
  For example:
    ...
    operatorLevel: 6
    teamManagerLevel: 10
    ...
    CTOLevel: 32
    ...

  If the owner wants to execute functions which require explicit authorization, it must authorize itself.
  
  If you need complex level, in the extended contract, you can add a function to generate unique roles based on combination of levels. The possibilities are almost unlimited, since the level is a uint256
*/

contract Authorizable is Ownable {

  uint public totalAuthorized;

  mapping(address => uint) public authorized;
  address[] internal __authorized;

  event AuthorizedAdded(address _authorizer, address _authorized, uint _level);

  event AuthorizedRemoved(address _authorizer, address _authorized);

  uint public maxLevel = 64;
  uint public authorizerLevel = 56;

  function setLevels(uint _maxLevel, uint _authorizerLevel) external onlyOwner {
    // this must be called before authorizing any address
    require(totalAuthorized == 0);
    require(_maxLevel > 0 && _authorizerLevel > 0);
    require(_maxLevel >= _authorizerLevel);

    maxLevel = _maxLevel;
    authorizerLevel = _authorizerLevel;
  }

  // Throws if called by any account which is not authorized.
  modifier onlyAuthorized() {
    require(authorized[msg.sender] > 0);
    _;
  }

  // Throws if called by any account which is not authorized at a specific level.
  modifier onlyAuthorizedAtLevel(uint _level) {
    require(authorized[msg.sender] == _level);
    _;
  }

  // Throws if called by any account which is not authorized at some of the specified levels.
  modifier onlyAuthorizedAtLevels(uint[] _levels) {
    require(__hasLevel(authorized[msg.sender], _levels));
    _;
  }

  // Throws if called by any account which is not authorized at a minimum required level.
  modifier onlyAuthorizedAtLevelMoreThan(uint _level) {
    require(authorized[msg.sender] > _level);
    _;
  }

  // Throws if called by any account which has a level of authorization less than a certan maximum.
  modifier onlyAuthorizedAtLevelLessThan(uint _level) {
    require(authorized[msg.sender] > 0 && authorized[msg.sender] < _level);
    _;
  }

  // same modifiers but including the owner

  modifier onlyOwnerOrAuthorized() {
    require(msg.sender == owner || authorized[msg.sender] > 0);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevel(uint _level) {
    require(msg.sender == owner || authorized[msg.sender] == _level);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevels(uint[] _levels) {
    require(msg.sender == owner || __hasLevel(authorized[msg.sender], _levels));
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevelMoreThan(uint _level) {
    require(msg.sender == owner || authorized[msg.sender] > _level);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevelLessThan(uint _level) {
    require(msg.sender == owner || (authorized[msg.sender] > 0 && authorized[msg.sender] < _level));
    _;
  }

  // Throws if called by anyone who is not an authorizer.
  modifier onlyAuthorizer() {
    require(msg.sender == owner || authorized[msg.sender] >= authorizerLevel);
    _;
  }


  // methods

  // Allows the current owner and authorized with level >= authorizerLevel to add a new authorized address, or remove it, setting _level to 0
  function authorize(address _address, uint _level) onlyAuthorizer external {
    __authorize(_address, _level);
  }

  // Allows the current owner to remove all the authorizations.
  function deAuthorizeAll() onlyOwner external {
    for (uint i = 0; i < __authorized.length; i++) {
      if (__authorized[i] != address(0)) {
        __authorize(__authorized[i], 0);
      }
    }
  }

  // Allows an authorized to de-authorize itself.
  function deAuthorize() onlyAuthorized external {
    __authorize(msg.sender, 0);
  }

  // internal functions
  function __authorize(address _address, uint _level) internal {
    require(_address != address(0));
    require(_level >= 0 && _level <= maxLevel);

    uint i;
    if (_level > 0) {
      bool alreadyIndexed = false;
      for (i = 0; i < __authorized.length; i++) {
        if (__authorized[i] == _address) {
          alreadyIndexed = true;
          break;
        }
      }
      if (alreadyIndexed == false) {
        __authorized.push(_address);
        totalAuthorized++;
      }
      AuthorizedAdded(msg.sender, _address, _level);
      authorized[_address] = _level;
    } else {
      for (i = 0; i < __authorized.length; i++) {
        if (__authorized[i] == _address) {
          __authorized[i] = address(0);
          totalAuthorized--;
          break;
        }
      }
      AuthorizedRemoved(msg.sender, _address);
      delete authorized[_address];
    }
  }

  function __hasLevel(uint _level, uint[] _levels) internal pure returns (bool) {
    bool has = false;
    for (uint i; i < _levels.length; i++) {
      if (_level == _levels[i]) {
        has = true;
        break;
      }
    }
    return has;
  }

  // helpers callable by other contracts

  function amIAuthorized() external constant returns (bool) {
    return authorized[msg.sender] > 0;
  }

}

// File: zeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/SubscriptionStore.sol

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

  function setTier(uint8 _tier, uint _duration) external onlyAuthorized {
    require(tiers[_tier] == 0);
    // There is no requirement for the _duration because
    // setting the _duration to 0 is equivalent to remove the tier

    tiers[_tier] = _duration;
  }

  function setSubscription(address _address, uint _txId, uint8 _tier) external onlyAuthorized {
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

  function getLastTransactionId(address _address) external constant returns (uint){
    return subscription[_address].lastTransactionId;
  }

  function getExpirationTimestamp(address _address) external constant returns (uint){
    return subscription[_address].expirationTimestamp;
  }

}
