pragma solidity ^0.4.24;

import "./ProvableOwnershipToken.sol";
import "./MintableBridgeToken.sol";
import "./BridgeToken.sol";
import "./MintableToken.sol";


/**
 * @title MintableBridgeToken
 * @dev MintableBridgeToken contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract MintableBridgeToken is MintableToken, BridgeToken {

  string public name;
  string public symbol;

  uint public decimals = 18;

  /**
   * @dev constructor
   */
  constructor(string _name, string _symbol)
    BridgeToken(_name, _symbol) public
  {
    name = _name;
    symbol = _symbol;
  }
}

