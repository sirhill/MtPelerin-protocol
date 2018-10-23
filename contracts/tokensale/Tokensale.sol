pragma solidity ^0.4.24;

import "../interface/IUserRegistry.sol";
import "../interface/ITokensale.sol";
import "../interface/IRatesProvider.sol";
import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/math/SafeMath.sol";
import "../Authority.sol";


/**
 * @title Tokensale
 * @dev Tokensale interface
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
 * TOS01: It must be before the sale is opened
 * TOS02: Sale must be open
 * TOS03: It must be after the sale is opened
 * TOS04: No data must be sent while sending ETH
 * TOS05: Share Purchase Agreement Hashes must match
 * TOS06: User/Investor must exist
 * TOS07: SPA must be accepted before any ETH investment
 * TOS08: Cannot update schedule once started
 * TOS09: Investor must exist
 * TOS10: Cannot allocate more tokens than available supply
 * TOS11: InvestorIds and amounts must match
 * TOS12: Investor must exist
 * TOS13: Must refund ETH unspent
 * TOS14: Must withdraw ETH to vaultETH
 * TOS15: Cannot invest onchain and offchain at the same time
 * TOS16: A ETHCHF rate must exist to invest
 * TOS17: User must be valid
 * TOS18: Cannot invest if no more tokens
 * TOS19: Cannot unspent more CHF than BASE_TOKEN_PRICE_CHF
 * TOS20: Token transfer must be successfull
 */
contract Tokensale is ITokensale, Authority {
  using SafeMath for uint256;

  /* General sale details */
  ERC20 public token;
  address public vaultETH;
  address public vaultERC20;
  IUserRegistry public userRegistry;
  IRatesProvider public ratesProvider;
  bytes32 public sharePurchaseAgreementHash;

  uint256 public startAt = 4102441200;
  uint256 public endAt = 4102441200;
  uint256 public raisedETH;
  uint256 public raisedCHF;
  uint256 public totalRaisedCHF;
  uint256 public refundedETH;
  uint256 public allocatedTokens;

  struct Investor {
    uint256 unspentETH;
    uint256 investedCHF;
    bool acceptedSPA;
    uint256 allocations;
    uint256 tokens;
  }
  mapping(uint256 => Investor) investors;
  uint256 public investorCount;

  /**
   * @dev Throws if sale is not open
   */
  modifier beforeSaleIsOpened {
    require(currentTime() < startAt, "TOS01");
    _;
  }

  /**
   * @dev Throws if sale is not open
   */
  modifier saleIsOpened {
    require(currentTime() >= startAt && currentTime() <= endAt, "TOS02");
    _;
  }

  /**
   * @dev Throws once the sale is closed
   */
  modifier beforeSaleIsClosed {
    require(currentTime() <= endAt, "TOS03");
    _;
  }

  /**
   * @dev constructor
   */
  constructor(
    ERC20 _token,
    IUserRegistry _userRegistry,
    IRatesProvider _ratesProvider,
    address _vaultERC20,
    address _vaultETH
  ) public
  {
    token = _token;
    userRegistry = _userRegistry;
    ratesProvider = _ratesProvider;
    vaultERC20 = _vaultERC20;
    vaultETH = _vaultETH;
  }

  /**
   * @dev fallback function
   */
  function () external payable {
    require(msg.data.length == 0, "TOS04");
    investETH();
  }

  /**
   * @dev returns the token sold
   */
  function token() public view returns (ERC20) {
    return token;
  }

  /**
   * @dev returns the vault use to
   */
  function vaultETH() public view returns (address) {
    return vaultETH;
  }

  /**
   * @dev returns the vault to receive ETH
   */
  function vaultERC20() public view returns (address) {
    return vaultERC20;
  }

  function userRegistry() public view returns (IUserRegistry) {
    return userRegistry;
  }

  function ratesProvider() public view returns (IRatesProvider) {
    return ratesProvider;
  }

  function sharePurchaseAgreementHash() public view returns (bytes32) {
    return sharePurchaseAgreementHash;
  }

  /* Sale status */
  function startAt() public view returns (uint256) {
    return startAt;
  }

  function endAt() public view returns (uint256) {
    return endAt;
  }

  function raisedETH() public view returns (uint256) {
    return raisedETH;
  }

  function raisedCHF() public view returns (uint256) {
    return raisedCHF;
  }

  function totalRaisedCHF() public view returns (uint256) {
    return totalRaisedCHF;
  }

  function refundedETH() public view returns (uint256) {
    return refundedETH;
  }

  function availableSupply() public view returns (uint256) {
    uint256 vaultSupply = token.balanceOf(vaultERC20);
    uint256 allowance = token.allowance(vaultERC20, address(this));
    return (vaultSupply < allowance) ? vaultSupply : allowance;
  }
 
  /* Investor specific attributes */
  function investorUnspentETH(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].unspentETH;
  }

  function investorInvestedCHF(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].investedCHF;
  }

  function investorAcceptedSPA(uint256 _investorId)
    public view returns (bool)
  {
    return investors[_investorId].acceptedSPA;
  }

  function investorAllocations(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].allocations;
  }

  function investorTokens(uint256 _investorId) public view returns (uint256) {
    return investors[_investorId].tokens;
  }

  function investorCount() public view returns (uint256) {
    return investorCount;
  }

  /* Share Purchase Agreement */
  /**
   * @dev define SPA
   */
  function defineSPA(bytes32 _sharePurchaseAgreementHash)
    public onlyOwner returns (bool)
  {
    sharePurchaseAgreementHash = _sharePurchaseAgreementHash;
    emit SalePurchaseAgreementHash(_sharePurchaseAgreementHash);
  }

  /**
   * @dev Accept SPA and invest if msg.value > 0
   */
  function acceptSPA(bytes32 _sharePurchaseAgreementHash)
    public beforeSaleIsClosed payable returns (bool)
  {
    require(
      _sharePurchaseAgreementHash == sharePurchaseAgreementHash, "TOS05");
    uint256 investorId = userRegistry.userId(msg.sender);
    require(investorId > 0, "TOS06");
    investors[investorId].acceptedSPA = true;
    investorCount++;

    if (msg.value > 0) {
      investETH();
    }
  }

  /* Investment */
  function investETH() public saleIsOpened payable {
    // This process is temporarily processed offchain
    //uint256 investorId = userRegistry.userId(msg.sender);
    //require(investors[investorId].acceptedSPA, "TOS07");
    investInternal(msg.sender, msg.value, 0);
    autoWithdrawETHFunds();
  }

  /**
   * @dev add off chain investment
   */
  function addOffChainInvestment(address _investor, uint256 _amountCHF)
    public onlyAuthority
  {
    investInternal(_investor, 0, _amountCHF);
  }

  /* Schedule */ 
  /**
   * @dev update schedule
   */
  function updateSchedule(uint256 _startAt, uint256 _endAt)
    public onlyAuthority beforeSaleIsOpened
  {
    require(_startAt < _endAt, "TOS08");
    startAt = _startAt;
    endAt = _endAt;
  }

  /* Allocations admin */
  /**
   * @dev allocate
   */
  function allocateTokens(address _investor, uint256 _amount)
    public onlyAuthority beforeSaleIsClosed returns (bool)
  {
    uint256 investorId = userRegistry.userId(_investor);
    require(investorId > 0, "TOS09");
    Investor storage investor = investors[investorId];
    
    allocatedTokens = allocatedTokens.sub(investor.allocations).add(_amount);
    require(allocatedTokens <= availableSupply(), "TOS10");

    investor.allocations = _amount;
    emit Allocation(investorId, _amount);
  }

  /**
   * @dev allocate many
   */
  function allocateManyTokens(address[] _investors, uint256[] _amounts)
    public onlyAuthority beforeSaleIsClosed returns (bool)
  {
    require(_investors.length == _amounts.length, "TOS11");
    for (uint256 i; i < _investors.length; i++) {
      allocateTokens(_investors[i], _amounts[i]);
    }
  }

  /* ETH administration */
  /**
   * @dev refund unspent ETH
   */
  function refundUnspentETH() public {
    uint256 investorId = userRegistry.userId(msg.sender);
    require(investorId != 0, "TOS12");
    Investor storage investor = investors[investorId];

    if (investor.unspentETH > 0) {
      // solium-disable-next-line security/no-send
      require(msg.sender.send(investor.unspentETH), "TOS13");
      refundedETH = refundedETH.add(investor.unspentETH);
      emit WithdrawETH(msg.sender, investor.unspentETH);
      investor.unspentETH = 0;
    }
  }

  /**
   * @dev withdraw ETH funds
   */
  function withdrawETHFunds() public {
    uint256 balance = address(this).balance;
    if (balance > MINIMAL_BALANCE) {
      uint256 amount = balance.sub(MINIMAL_BALANCE);
      // solium-disable-next-line security/no-send
      require(vaultETH.send(amount), "TOS14");
      emit WithdrawETH(vaultETH, amount);
    }
  }

  /**
   * @dev auto withdraw ETH funds
   */
  function autoWithdrawETHFunds() public {
    uint256 balance = address(this).balance;
    if (balance >= MINIMAL_BALANCE.add(MINIMAL_AUTO_WITHDRAW)) {
      uint256 amount = balance.sub(MINIMAL_BALANCE);
      // solium-disable-next-line security/no-send
      if (vaultETH.send(amount)) {
        emit WithdrawETH(vaultETH, amount);
      }
    }
  }

  /**
   * @dev invest internal
   */
  function investInternal(
    address _investor, uint256 _amountETH, uint256 _amountCHF)
    private
  {
    // investment with _amountETH is decentralized
    // investment with _amountCHF is centralized
    // They are mutually exclusive
    require((_amountETH != 0 && _amountCHF == 0) ||
      (_amountETH == 0 && _amountCHF != 0), "TOS15");

    require(ratesProvider.rateWEIPerCHFCent() != 0, "TOS16");
    uint256 investorId = userRegistry.userId(_investor);
    require(userRegistry.isValid(investorId), "TOS17");

    Investor storage investor = investors[investorId];

    uint256 contributionCHF = ratesProvider.convertWEIToCHFCent(
      investor.unspentETH);

    if (_amountETH > 0) {
      contributionCHF = contributionCHF.add(
        ratesProvider.convertWEIToCHFCent(_amountETH));
    }
    if (_amountCHF > 0) {
      contributionCHF = contributionCHF.add(_amountCHF);
    }

    uint256 tokens = contributionCHF.div(BASE_PRICE_CHF_CENT);
    uint256 availableTokens = availableSupply().sub(
      allocatedTokens).add(investor.allocations);
    require(availableTokens != 0, "TOS18");

    if (tokens > availableTokens) {
      tokens = availableTokens;
    }

    /** Calculating unspentETH value **/
    uint256 investedCHF = tokens.mul(BASE_PRICE_CHF_CENT);
    uint256 unspentContributionCHF = contributionCHF.sub(investedCHF);

    uint256 unspentETH = 0;
    if (unspentContributionCHF != 0) {
      if (_amountCHF > 0) {
        // Prevent CHF investment LARGER than available supply
        // from creating a too large and dangerous unspentETH value
        require(unspentContributionCHF < BASE_PRICE_CHF_CENT, "TOS19");
      }
      unspentETH = ratesProvider.convertCHFCentToWEI(
        unspentContributionCHF);
    }

    /** Spent ETH **/
    uint256 spentETH = 0;
    if (investor.unspentETH == unspentETH) {
      spentETH = _amountETH;
    } else {
      uint256 unspentETHDiff = (unspentETH > investor.unspentETH)
        ? unspentETH.sub(investor.unspentETH)
        : investor.unspentETH.sub(unspentETH);

      if (_amountCHF > 0) {
        if (unspentETH < investor.unspentETH) {
          spentETH = unspentETHDiff;
        }
        // if unspentETH > investor.unspentETH
        // then CHF has been converted into ETH
        // and no ETH were spent
      }
      if (_amountETH > 0) {
        spentETH = (unspentETH > investor.unspentETH)
          ? _amountETH.sub(unspentETHDiff)
          : _amountETH.add(unspentETHDiff);
      }
    }

    investor.unspentETH = unspentETH;
    investor.investedCHF = investor.investedCHF.add(investedCHF);
    investor.tokens = investor.tokens.add(tokens);
    raisedCHF = raisedCHF.add(_amountCHF);
    raisedETH = raisedETH.add(spentETH);
    totalRaisedCHF = totalRaisedCHF.add(investedCHF);

    allocatedTokens = allocatedTokens.sub(investor.allocations);
    investor.allocations = (investor.allocations > tokens)
      ? investor.allocations.sub(tokens) : 0;
    allocatedTokens = allocatedTokens.add(investor.allocations);
    require(
      token.transferFrom(vaultERC20, _investor, tokens),
      "TOS20");

    if (spentETH > 0) {
      emit ChangeETHCHF(
        _investor,
        spentETH,
        ratesProvider.convertWEIToCHFCent(spentETH),
        ratesProvider.rateWEIPerCHFCent());
    }
    emit Investment(investorId, investedCHF);
  }

  /* Util */
  /**
   * @dev current time
   */
  function currentTime() private view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return now;
  }
}
