pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/StandardToken.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../rule/WithRules.sol";
import "../interface/IRule.sol";


/**
 * @title TokenWithRules
 * @dev TokenWithRules contract
 * TokenWithRules is a token that will apply
 * rules restricting transferability
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 **/
contract TokenWithRules is StandardToken, WithRules {

  /**
   * @dev Constructor
   */
  constructor(IRule[] _rules) public WithRules(_rules) { }

  /**
   * @dev Overriden transfer function
   */
  function transfer(address _to, uint256 _value)
    public whenTransferRulesAreValid(msg.sender, _to, _value)
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  /**
   * @dev Overriden transferFrom function
   */
  function transferFrom(address _from, address _to, uint256 _value)
    public whenTransferRulesAreValid(_from, _to, _value)
    whenAddressRulesAreValid(msg.sender)
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }
}
