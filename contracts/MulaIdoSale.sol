// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 

import "./MulaIdoUtils.sol";
import "./MulaIdoVestor.sol";


contract MulaIdoSale  is ReentrancyGuard,MulaIdoUtils{

  using SafeMath for uint256;
  IERC20  _tokenContract;
  MulaIdoVestor _vestor;
  
  mapping(CrowdsaleStage=> mapping(address => uint256)) _receiving;
  mapping(CrowdsaleStage=> uint256) public CrowdsaleStageBalance;

    /**
    * @dev Reverts if not in crowdsale time range.
    **/
    modifier onlyWhileOpen {
        require(isOpen(), "IDO: not open");
        _;
    }

    constructor(
        IERC20 token,
        IERC20 _USDT,
        MulaIdoVestor vestor,
        uint256 startingTime,
        uint256 endingTime,
        address payable wallet
    )
    ReentrancyGuard()
    { 
        require(startingTime >= block.timestamp, "Crowdsale: start time is before current time");
        require(endingTime > startingTime, "Crowdsale: start time is invalid");
        _tokenContract = token;//link to token contract 
        _USDTContract = _USDT; //link to token vault contract 
        _vestor = vestor; //ido vesting contract
        _wallet = wallet;//token wallet 
        _startTime = startingTime;//set periods management
        _endTime = endingTime;//set periods management
    }
    function participateBNB(uint80 _roundId) payable public onlyWhileOpen returns (bool){
        uint256 _numberOfTokens = _MulaReceiving(msg.value,_roundId);
        _preValidateParticipation(_numberOfTokens, msg.sender);
        //require that the transaction is successful 
        _processParticipationBNB(msg.sender, _numberOfTokens);
        
        _postParticipation(msg.sender,_numberOfTokens);  
        return true;
    }
    function participateUSDT(uint80 _roundId) public onlyWhileOpen returns(bool){
        require(_USDTContract.allowance(msg.sender, address(this)) > 0);
        //calculate number of tokens
        uint usdVal  = _USDTContract.allowance(msg.sender, address(this));
        uint bnbEquv = (usdVal.div(uint256(getBNBUSDPrice(_roundId)))).mul(_crossDecimal);
        uint256 _numberOfTokens = _MulaReceiving(bnbEquv,_roundId);
        //validate transaction
        _preValidateParticipation(_numberOfTokens, msg.sender);
        //receive Investment
        require(_USDTContract.transferFrom(msg.sender, address(this), usdVal));
        //distribute tokens 
        _processParticipationUSDT(msg.sender, _numberOfTokens,usdVal);
        //finalise sale
        _postParticipation(msg.sender,_numberOfTokens);
        
       return true;
    }

    //sets the ICO Stage, rates  and the CrowdsaleStageBalance 
    function updateStage(uint _stage)public onlyOwner returns (bool){
      
        if (uint(CrowdsaleStage.PublicSale) == _stage) {
            // emptyStageBalanceToBurnBucket();
            stage = CrowdsaleStage.PublicSale;
            CrowdsaleStageBalance[stage]=27500000 * (10**18); //
            _rate = 0.065 * (10**8); // usd
        }else if(uint(CrowdsaleStage.Paused) == _stage){
            stage = CrowdsaleStage.Paused;
            _rate = 0; //0.00 eth
        }else if(uint(CrowdsaleStage.Ended) == _stage){
            stage = CrowdsaleStage.Ended;
            CrowdsaleStageBalance[stage]=0;
            _rate = 0; //0.00 eth
        }
        return true;
    }
    
    function getStageBalance() public view returns (uint256) {
        return CrowdsaleStageBalance[stage];
    }
    
    function getParticipantReceivings(CrowdsaleStage _stage,address _participant) public view returns (uint256){
        return _receiving[_stage][_participant];
    }
    function _updateParticipantBalance(address _participant,uint256 _numOfTokens) internal returns (bool){
        uint256 oldReceivings = getParticipantReceivings(stage,_participant);
        uint256 newReceiving = oldReceivings.add(_numOfTokens);
        _receiving[stage][_participant] = newReceiving;
        return true;
    }
    //check if investor falls between contribution caps
    function _isIndividualCapped(address _participant, uint256 _numberOfTokens)  internal view returns (bool){
        require(_numberOfTokens >= investorMinContribution,'Investor does not meet the minimum contribution.' );
        uint256 _oldReceivings = getParticipantReceivings(stage,_participant);
        uint256 _newReceiving = _oldReceivings.add(_numberOfTokens);
        require(_newReceiving <= investorMaxContribution , 'Investor exceeds the maximum contribution.');
        return true;
    }
    function _preValidateParticipation(uint256 _numberOfTokens, address _participant) internal view {
        //Require that contract has enough tokens 
        require(_tokenContract.balanceOf(address(this)) >= _numberOfTokens,'token requested not available');
        //require that participant giving is between the caped range per stage
        require(_isIndividualCapped(_participant,  _numberOfTokens),'request not within the cap range');
    }
    function _processParticipationBNB(address recipient, uint256 amount) nonReentrant() internal{
        //forward funds to wallet
        require( _forwardBNBFunds()); 
        //forward 20% to investor
        require(_tokenContract.transfer(recipient, calculatePercent(20, amount)));
        //forward 80% to IDO vault 
        require(_tokenContract.transfer(address(_vestor), calculatePercent(80, amount)));
        //create investor record on vestor 
        require(_vestor.recordInvestment(recipient,amount));
        _weiRaisedBNB += amount;
    }
    function _processParticipationUSDT(address recipient, uint256 amount,uint256 usdtInvestment) nonReentrant() internal{
        //forward funds to wallet
        require( _forwardUSDTFunds(usdtInvestment));
        //forward 20% to investor
        require(_tokenContract.transfer(recipient, calculatePercent(20, amount)));
        //forward 80% to IDO vault 
        require(_tokenContract.transfer(address(_vestor), calculatePercent(80, amount)));
        //create investor record on vestor 
        require(_vestor.recordInvestment(recipient,amount));
        _weiRaisedBUSD += amount;
    }
    function _postParticipation(address _participant, uint256 _numberOfTokens) nonReentrant() internal returns(bool){
        //record participant givings and receivings
        require(_updateParticipantBalance(_participant,_numberOfTokens));
        //track number of tokens sold  and amount raised
        _tokensSold += _numberOfTokens;
        //subtract from crowdsale stage balance 
        return true;
    }
    //close IDO sale
    function finalize() public onlyOwner{

        require(!isFinalized(), "Crowdsale: already finalized");
        require(updateStage(2),"Crowdsale: should be marked as ended");

        //send the remaining sale tokens to the collection wallet 
        uint256 saleBal = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_wallet,saleBal);

        _finalized = true;
    }
    
}
