// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract MulaIdoUtils is Ownable {

  //sale Stages
  enum CrowdsaleStage {PublicSale,Paused,Ended }
  // Default to presale stage
  CrowdsaleStage public stage = CrowdsaleStage.Paused;

  uint256 public _rate;
  uint256 public _tokensSold;
  uint256 public _weiRaisedBNB;
  uint256 public _weiRaisedBUSD;
  uint256 _startTime;
  uint256 _endTime;
  uint256  investorMinContribution;
  uint256  investorMaxContribution;
  uint256 _crossDecimal = 10**8;

  bool _finalized = false;

  IERC20 public _USDTContract;
  AggregatorV3Interface internal BNBUSD;

  event BuyMula(address indexed _from,uint256 indexed _tokens,uint256  _value);

  address payable _wallet;
  constructor()  Ownable(){
  }

  
  function setContributionCaps(uint256 _minContribution, uint256 _maxContribution) public onlyOwner returns (bool){
    investorMinContribution = _minContribution;
    investorMaxContribution = _maxContribution;
    return true;
  }

  function getMaxCap() public view returns (uint256){
      return investorMaxContribution;
  }
  function getMinCap() public view returns (uint256){
      return investorMinContribution;
  }
  function startTime() public view returns (uint256) {
      return _startTime;
  }
  function endTime() public view returns (uint256) {
      return _endTime;
  }
  function isOpen() public view returns (bool) {
      require(block.timestamp >= _startTime && block.timestamp <= _endTime ,"Crowdsale: not opened");
      require(stage != CrowdsaleStage.Paused && stage != CrowdsaleStage.Ended,"Crowdsale: not opened");
      return true;
  }
  function hasClosed() public view returns (bool) {
      return block.timestamp > _endTime;
  }

  function extendTime(uint256 newEndTime) public onlyOwner {
      require(!hasClosed(), "Crowdsale: close already");
      require(newEndTime > _endTime, "Crowdsale: new endtime must be after current endtime");
      _endTime = newEndTime;
      
  }

    function _MulaReceiving(uint256 _weiSent, uint80 _roundId) public view returns (uint256 ){
        int _channelRate = 0;
        // _channelRate  =  getBNBUSDPrice(_roundId);
        _channelRate  =  39918000000;
        int _MulaRate = int(_rate)/(_channelRate/int(_crossDecimal));
        uint256 _weiMedRate =  uint256((_MulaRate * 10 **18 )/int(_crossDecimal));
        uint256 tempR = _weiSent/_weiMedRate;
        return tempR * 10 ** 18;
    }
    function setBNBUSDTAggregator(address _aggregator) public  onlyOwner() returns (bool){
         BNBUSD = AggregatorV3Interface(_aggregator);
         return true;
    }
    function getBNBUSDPrice(uint80 roundId) public view returns (int) {
        (
            uint80 id, 
            int price,
            uint startedAt,
            uint timeStamp,
        ) = BNBUSD.getRoundData(roundId);
         require(timeStamp > 0, "Round not complete");
         require(block.timestamp <= timeStamp + 1 days);
        return price;
    }
  /**
    * @dev forwards funds to the sale Wallet
    */
    function _forwardBNBFunds() internal returns (bool){
        _wallet.transfer(msg.value);
        return true;
    }
    /**
    * @dev forwards funds to the sale Wallet
    */
    function _forwardUSDTFunds(uint256 amount) internal returns (bool){
        _USDTContract.transfer(_wallet,amount);
        return true;
    }

  function isFinalized() public view returns (bool) {
      return _finalized;
  }
  function calculatePercent(uint numerator, uint denominator) internal  pure returns (uint256){
    return (denominator * (numerator * 100) ) /10000;
  }
}
