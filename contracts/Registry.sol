pragma solidity ^0.4.24;

import "./interface/IRegistry.sol";
import "./zeppelin/ownership/Ownable.sol";


/**
 * @title Registry
 * @dev Registry contract
 * This contract store addresses only updatable by the owner.
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
 * RE01: address Id does not exist
 * RE02: ids cannot be empty
 * RE03: addresses must match with ids
*/
contract Registry is IRegistry, Ownable {
  address[] internal addresses;
  string public name;

  /**
   * @dev Constructor
   */
  constructor(string _name, address[] _addresses) public {
    name = _name;
    addresses = _addresses;
  }

  /**
   * @dev getter need to be declared to comply with IRegistry interface
   */
  function name() public view returns (string) {
    return name;
  }

   /**
   * @dev called to get the count of addresses in the Registry
   */
  function addressLength() public view returns (uint256) {
    return addresses.length;
  }

  /**
   * @dev called to get the address at a specific index 
   **/
  function addressById(uint256 _id) public view returns (address) {
    return addresses[_id];
  }

  /**
   * @dev called by the owner to add an address to the registry
   **/
  function addAddress(address _address) public onlyOwner returns (uint256) {
    addresses.push(_address);
    emit AddressAdded(addresses.length, _address);
    return addresses.length;
  }

  /**
   * @dev called by the owner to remove an address at a specific index 
   **/
  function removeAddressById(uint256 _id) public onlyOwner returns (address) {
    require(_id < addresses.length, "RE01");
    address result = addresses[_id];

    if (_id != addresses.length-1) {
      addresses[_id] = addresses[addresses.length-1];
    }
    addresses.length--;
    emit AddressRemoved(_id, result);
    return result;
  }

  /**
   * @dev called by the owner to replace the address at a specific index 
   **/
  function replaceAddressById(uint256 _id, address _address)
    public onlyOwner returns (address)
  {
    require(_id < addresses.length, "RE01");
    address result = addresses[_id];

    addresses[_id] = _address;
    emit AddressReplaced(_id, _address, result);
    return result;
  }

  /**
   * @dev called by the owner to replace many the addresses at specific indexes
   **/
  function replaceManyAddressesByIds(uint256[] _indexes, address[] _addresses)
    public onlyOwner
  {
    require(_indexes.length > 0, "RE02");
    require(_indexes.length == _addresses.length, "RE03");
    for (uint256 i = 0; i<_indexes.length ; i++) {
      address result = addresses[_indexes[i]];
      addresses[_indexes[i]] = _addresses[i];
      emit AddressReplaced(_indexes[i], _addresses[i], result);
    }
  }
}
