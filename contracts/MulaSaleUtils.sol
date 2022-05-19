// SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MulaSaleUtils is Ownable {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
  //sale Stages
    enum CrowdsaleStage {PublicSale,Paused,Ended }
    // Default to presale stage
    CrowdsaleStage public stage = CrowdsaleStage.Paused;

    uint256 public _rate;
    uint256 public _tokensSold;
    uint256 public _weiRaisedBNB;
    uint256 public _weiRaisedBUSD;
    uint256 private immutable _startTime;
    uint256 private _endTime;
    uint256 public  investorMinContribution;
    uint256 public  investorMaxContribution;
    uint256 private constant _crossDecimal = 10**8; 

    bool _finalized = false;

    IERC20 public immutable _USDTContract;
    AggregatorV3Interface immutable public BNBUSD;

    event BuyMula(address indexed _from,uint256 indexed _tokens,uint256  _value);
    event ContributionCapsSet(uint256 _minContribution, uint256 _maxContribution);
    event SaleIsFinalize(uint256 firstListingDate);
    event SaleStageUpdated(CrowdsaleStage stage);

    address payable immutable public _wallet;

    constructor(
        address _aggregator,
        IERC20 _USDT,
        uint256 startingTime,
        uint256 endingTime,
        address payable wallet)  Ownable(){
            BNBUSD = AggregatorV3Interface(_aggregator);
            _USDTContract = _USDT; //link to token vault contract 
            _wallet = wallet;//token wallet 
            _startTime = startingTime;//set periods management
            _endTime = endingTime;//set periods management
        }

    function setContributionCaps(uint256 _minContribution, uint256 _maxContribution) public onlyOwner returns (bool){
        investorMinContribution = _minContribution;
        investorMaxContribution = _maxContribution;
        emit ContributionCapsSet(investorMinContribution,investorMaxContribution);
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
        if (isStillCrowdSaleTime() && isCrowdSaleStageValid()) {
        return true;  
        } 
        return false;
    }
    function isStillCrowdSaleTime()public view returns(bool){
        if (block.timestamp >= _startTime && block.timestamp <= _endTime) {
            return true;
        }
        return false;
    }
    function isCrowdSaleStageValid()public view returns(bool){
        CrowdsaleStage _s = stage;
        if(_s != CrowdsaleStage.Paused && _s != CrowdsaleStage.Ended){
            return true;
        }
        return false;
    }
    function hasClosed() public view returns (bool) {
        return block.timestamp > _endTime;
    }

    function extendTime(uint256 newEndTime) public onlyOwner {
        require(newEndTime > _endTime, "Sale: new endtime must be after current endtime");
        _endTime = newEndTime;
        
    }

    function _MulaReceiving(uint256 _weiSent) public view returns (uint256 ){
        int _channelRate = 0;
        uint256 _cd = _crossDecimal;
        uint256 _weiConverter = 10 ** 18;
        _channelRate  = getBNBUSDPrice();  
        int _MulaRate = _rate.toInt256()/(_channelRate/_cd.toInt256());
        uint256 _weiMedRate =  ((_MulaRate * _weiConverter.toInt256() )/_cd.toInt256()).toUint256();
        uint256 tempR = _weiSent.div(_weiMedRate);
        return tempR * _weiConverter;
    }
    
    function getBNBUSDPrice() public view returns (int) {
        ( ,int price,,uint timeStamp,) = BNBUSD.latestRoundData();
        require(timeStamp > 0, "Round not complete");
        require(block.timestamp <= timeStamp + 1 days,"invalid roundID. try again.");
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
        return (denominator.mul(numerator.mul(100))).div(10000);
    }
}
