pragma solidity ^0.4.24;

import "./Authority.sol";
import "./interface/IRule.sol";
import "./interface/IUserRegistry.sol";


/**
 * @title UserRegistry
 * @dev UserRegistry contract
 * Configure and manage users
 * Extended may be used externaly to store data within a user context
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * UR01: Users length does not match with Addresses
 * UR02: UserId is invalid
 * UR03: Address is invalid
 * UR04: Address is already confirmed
 * UR05: User is already locked
 * UR06: User is not locked
*/
contract UserRegistry is IUserRegistry, Authority {

  struct User {
    uint256 validUntilTime;
    bool locked;
    mapping(uint256 => uint256) extended;
  }
  struct Address {
    uint256 userId;
    bool confirmed;
  }

  mapping(uint256 => User) internal users;
  mapping(address => Address) internal addresses;
  uint256 public userCount;

  /**
   * @dev contructor
   **/
  constructor(address[] _ownerAddresses, uint256 _validUntilTime) public {
    for (uint256 i = 0; i < _ownerAddresses.length; i++) {
      registerUserInternal(_ownerAddresses[i], _validUntilTime);
      addresses[_ownerAddresses[i]].confirmed = true;
    }
  }

  /**
   * @dev register many users
   */
  function registerManyUsers(address[] _addresses, uint256 _validUntilTime)
    public onlyAuthority
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      registerUserInternal(_addresses[i], _validUntilTime);
    }
  }

  /**
   * @dev attach many addresses to many users
   */
  function attachManyAddresses(uint256[] _userIds, address[] _addresses)
    public onlyAuthority
  {
    require(_addresses.length == _userIds.length, "UR01");
    for (uint256 i = 0; i < _addresses.length; i++) {
      attachAddress(_userIds[i], _addresses[i]);
    }
  }

  /**
   * @dev detach many addresses association between addresses and their respective users
   */
  function detachManyAddresses(address[] _addresses) public onlyAuthority {
    for (uint256 i = 0; i < _addresses.length; i++) {
      detachAddress(_addresses[i]);
    }
  }

  /**
   * @dev number of user registred
   */
  function userCount() public view returns (uint256) {
    return userCount;
  }

  /**
   * @dev the userId associated to the provided address
   */
  function userId(address _address) public view returns (uint256) {
    return addresses[_address].userId;
  }

  /**
   * @dev the userId associated to the provided address if the user is valid
   */
  function validUserId(address _address) public view returns (uint256) {
    if (isAddressValid(_address)) {
      return addresses[_address].userId;
    }
    return 0;
  }

  /**
   * @dev the userId associated to the provided address
   */
  function addressConfirmed(address _address) public view returns (bool) {
    return addresses[_address].confirmed;
  }

  /**
   * @dev returns the time at which user validity ends
   */
  function validUntilTime(uint256 _userId) public view returns (uint256) {
    return users[_userId].validUntilTime;
  }

  /**
   * @dev is the user locked
   */
  function locked(uint256 _userId) public view returns (bool) {
    return users[_userId].locked;
  }

  /**
   * @dev access to extended user data
   */
  function extended(uint256 _userId, uint256 _key)
    public view returns (uint256)
  {
    return users[_userId].extended[_key];
  }

  /**
   * @dev validity of the current user
   */
  function isAddressValid(address _address) public view returns (bool) {
    return addresses[_address].confirmed
      && isValid(addresses[_address].userId);
  }

  /**
   * @dev validity of the current user
   */
  function isValid(uint256 _userId) public view returns (bool) {
    return isValidInternal(users[_userId]);
  }

  /**
   * @dev register a user
   */
  function registerUser(address _address, uint256 _validUntilTime)
    public onlyAuthority
  {
    registerUserInternal(_address, _validUntilTime);
  }

  /**
   * @dev register a user
   */
  function registerUserInternal(address _address, uint256 _validUntilTime)
    public
  {
    require(addresses[_address].userId == 0, "UR03");
    users[++userCount] = User(_validUntilTime, false);
    addresses[_address] = Address(userCount, false);
  }

  /**
   * @dev attach an address with a user
   */
  function attachAddress(uint256 _userId, address _address) public onlyAuthority {
    require(_userId > 0 && _userId <= userCount, "UR02");
    require(addresses[_address].userId == 0, "UR03");
    addresses[_address] = Address(_userId, false);
  }

  /**
   * @dev confirm the address by the user to activate it
   */
  function confirmSelf() public {
    require(addresses[msg.sender].userId != 0, "UR03");
    require(!addresses[msg.sender].confirmed, "UR04");
    addresses[msg.sender].confirmed = true;
  }

  /**
   * @dev detach the association between an address and its user
   */
  function detachAddress(address _address) public onlyAuthority {
    require(addresses[_address].userId != 0, "UR03");
    delete addresses[_address];
  }

  /**
   * @dev detach the association between an address and its user
   */
  function detachSelf() public {
    detachSelfAddress(msg.sender);
  }

  /**
   * @dev detach the association between an address and its user
   */
  function detachSelfAddress(address _address) public {
    uint256 senderUserId = addresses[msg.sender].userId;
    require(senderUserId != 0, "UR03");
    require(addresses[_address].userId == senderUserId, "UR06");
    delete addresses[_address];
  }

  /**
   * @dev lock a user
   */
  function lockUser(uint256 _userId) public onlyAuthority {
    require(_userId > 0 && _userId <= userCount, "UR02");
    require(!users[_userId].locked, "UR06");
    users[_userId].locked = true;
  }

  /**
   * @dev unlock a user
   */
  function unlockUser(uint256 _userId) public onlyAuthority {
    require(_userId > 0 && _userId <= userCount, "UR02");
    require(users[_userId].locked, "UR06");
    users[_userId].locked = false;
  }

  /**
   * @dev lock many users
   */
  function lockManyUsers(uint256[] _userIds) public onlyAuthority {
    for (uint256 i = 0; i < _userIds.length; i++) {
      lockUser(_userIds[i]);
    }
  }

  /**
   * @dev unlock many users
   */
  function unlockManyUsers(uint256[] _userIds) public onlyAuthority {
    for (uint256 i = 0; i < _userIds.length; i++) {
      unlockUser(_userIds[i]);
    }
  }

  /**
   * @dev update a user
   */
  function updateUser(uint256 _userId, uint256 _validUntilTime, bool _locked)
    public onlyAuthority
  {
    require(_userId > 0 && _userId <= userCount, "UR02");
    users[_userId].validUntilTime = _validUntilTime;
    users[_userId].locked = _locked;
  }

  /**
   * @dev update many users
   */
  function updateManyUsers(
    uint256[] _userIds,
    uint256 _validUntilTime,
    bool _locked) public onlyAuthority
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      updateUser(_userIds[i], _validUntilTime, _locked);
    }
  }

  /**
   * @dev update user extended information
   */
  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    public onlyAuthority
  {
    require(_userId > 0 && _userId <= userCount, "UR02");
    users[_userId].extended[_key] = _value;
  }

  /**
   * @dev update many user extended informations
   */
  function updateManyUsersExtended(
    uint256[] _userIds,
    uint256 _key,
    uint256 _value) public onlyAuthority
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      updateUserExtended(_userIds[i], _key, _value);
    }
  }

  /**
   * @dev validity of the current user
   */
  function isValidInternal(User user) internal view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return !user.locked && user.validUntilTime > now;
  }
}
