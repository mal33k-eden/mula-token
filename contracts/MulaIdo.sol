// SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "./MulaSaleUtils.sol";
import "./MulaIdoVestor.sol";


contract MulaIdo  is ReentrancyGuard,MulaSaleUtils{
using SafeMath for uint256;
IERC20 immutable public _tokenContract;
MulaIdoVestor immutable public _vestor; 
mapping(CrowdsaleStage=> mapping(address => uint256)) private _receiving;
mapping(CrowdsaleStage=> uint256) public CrowdsaleStageBalance;

    /**
    * @dev Reverts if not in crowdsale time range.
    **/
    modifier onlyWhileOpen {
        require(isOpen(), "Sale: not open");
        _;
    }

    constructor(
        IERC20 token,
        IERC20 _USDT,
        MulaIdoVestor vestor,
        uint256 startingTime,
        uint256 endingTime,
        address payable wallet,
        address _aggregator
    )
    ReentrancyGuard()
    MulaSaleUtils(_aggregator,_USDT,startingTime,endingTime,wallet)
    { 
        require(startingTime >= block.timestamp, "Sale: start time is before current time");
        require(endingTime > startingTime, "Sale: start time is invalid");
        _tokenContract = token;//link to token contract 
        _vestor = vestor; //ido vesting contract
    }
    function participateBNB() payable public nonReentrant() onlyWhileOpen returns (bool){
        uint256 _numberOfTokens = _MulaReceiving(msg.value);
        _preValidateParticipation(_numberOfTokens, msg.sender);
        //require that the transaction is successful 
        _processParticipationBNB(msg.sender, _numberOfTokens); 
        _postParticipation(msg.sender,_numberOfTokens);  
        return true;
    }
    function participateUSDT() public  nonReentrant() onlyWhileOpen returns(bool){
        uint256 usdVal = _USDTContract.allowance(msg.sender, address(this));
        require(usdVal > 0,"no allowance created");
        //calculate number of tokens  
        uint256 _numberOfTokens = _rate.mul(usdVal);
        // validate transaction
        _preValidateParticipation(_numberOfTokens, msg.sender);
        //receive Investment
        require(_USDTContract.transferFrom(msg.sender, address(this), usdVal),'transfer not successful');
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
        emit SaleStageUpdated(stage);
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
    function _processParticipationBNB(address recipient, uint256 amount)  internal{
        
        //forward funds to wallet
        require( _forwardBNBFunds(),"Error sending BNB value. check your wallet balance"); 
        //forward 100% to investor
        require(_tokenContract.transfer(address(_vestor), amount), "sending tokens to investors failed");
        //create investor record on vestor 
        require(_vestor.recordInvestment(recipient,amount),"investments not recorded");
        _weiRaisedBNB = _weiRaisedBNB.add(amount);
    }
    function _processParticipationUSDT(address recipient, uint256 amount,uint256 usdtInvestment)   internal{
        //forward funds to wallet
        require( _forwardUSDTFunds(usdtInvestment),"Error sending USDT value. check your wallet balance");
        //forward 100% to IDO vault 
        require(_tokenContract.transfer(address(_vestor), amount), "sending tokens to investors failed");
        //create investor record on vestor 
        require(_vestor.recordInvestment(recipient,amount), "sending tokens to investors failed");
        _weiRaisedBNB = _weiRaisedBNB.add(amount);
    }
    function _postParticipation(address _participant, uint256 _numberOfTokens)  internal returns(bool){
        //record participant givings and receivings
        require(_updateParticipantBalance(_participant,_numberOfTokens),'not able to record participants giving');
        //track number of tokens sold  and amount raised
        _tokensSold= _tokensSold.add(_numberOfTokens);
        //subtract from crowdsale stage balance 
        return true;
    }
    //close IDO sale
    function finalize(uint256 firstListingDate) public onlyOwner{

        require(!isFinalized(), "Sale: already finalized");
        require(updateStage(2),"Sale: should be marked as ended");

        //send the remaining sale tokens to the collection wallet 
        uint256 saleBal = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_wallet,saleBal);
        _vestor.setVestingDates(firstListingDate);
        _finalized = true;
        emit SaleIsFinalize(firstListingDate);
    }
    
}
