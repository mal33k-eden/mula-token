// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./MulaVestorUtils.sol";

contract MulaSeedVestor is MulaVestorUtils{
  
  mapping(address => mapping(VestingStages=>bool)) public tracker; 
  mapping(address => uint256) public investment; 
  
 
  event LogVestingWithdrawal(address beneficiary, uint256 amount);
  constructor(){
    
  }
  
  function getInvestmentTotal(address beneficiary) public view returns(uint256) {
    return investment[beneficiary];
  }
  function getVestingDetails(uint256 vestStage, address beneficiary) public view returns (uint256,bool){
    uint256 vestDate;
    bool status;
    
    if(uint(VestingStages.TGE) == vestStage){
        vestDate =provisionDates[VestingStages.TGE];
        status = tracker[beneficiary][VestingStages.TGE];
        return (vestDate,status);
    }else if(uint(VestingStages.M2) == vestStage){
        vestDate =provisionDates[VestingStages.M2];
        status = tracker[beneficiary][VestingStages.M2];
        return (vestDate,status);
    }else if(uint(VestingStages.M3) == vestStage){
        vestDate =provisionDates[VestingStages.M3];
        status = tracker[beneficiary][VestingStages.M3];
        return (vestDate,status);
    }else if(uint(VestingStages.M4) == vestStage){
        vestDate =provisionDates[VestingStages.M4];
        status = tracker[beneficiary][VestingStages.M4];
        return (vestDate,status);
    }else if(uint(VestingStages.M12) == vestStage){
        vestDate =provisionDates[VestingStages.M12];
        status = tracker[beneficiary][VestingStages.M12];
        return (vestDate,status);
    }else{
      return (0,status);
    }
    
  }
  function getVestTracker() public view returns (bool tge,bool m2,bool m3,bool m4,bool m12){
    address beneficiary = msg.sender;
    tge = tracker[beneficiary][VestingStages.TGE];
    m2  = tracker[beneficiary][VestingStages.M2];
    m3  = tracker[beneficiary][VestingStages.M3];
    m4  = tracker[beneficiary][VestingStages.M4];
    m12 = tracker[beneficiary][VestingStages.M12];

    return (tge,m2,m3,m4,m12);
  }
  function recordInvestment(address beneficiary, uint256 newTotal) onlyOperator public returns(bool) {
    uint256 _total = investment[beneficiary];
    investment[beneficiary] = _total + newTotal;
    investors[beneficiary]= true;
    return true;
  }

  function updateVestingDetails(uint256 vestStage, address beneficiary,bool status) internal returns (bool){
    if(uint(VestingStages.TGE) == vestStage){
      tracker[beneficiary][VestingStages.TGE] = status;
    }
    if(uint(VestingStages.M2) == vestStage){
      tracker[beneficiary][VestingStages.M2] = status;
    }
    if(uint(VestingStages.M3) == vestStage){
      tracker[beneficiary][VestingStages.M3] = status;
    }
    if(uint(VestingStages.M4) == vestStage){
      tracker[beneficiary][VestingStages.M4] = status;
    }
    if(uint(VestingStages.M12) == vestStage){
      tracker[beneficiary][VestingStages.M12] = status;
    }
    return true;
  }

  function withdrawInvestment(uint256 vestStage) public returns(bool success) {
    
    require(isInvestor(msg.sender), 'Sorry! you are not an investor.');
    (
      uint256 vestDate,
      bool status
    ) = getVestingDetails(vestStage,msg.sender);
    require(vestDate != 0, 'Invalid vesting stagee');
    require(vestDate <= block.timestamp,'vault still locked');
    require(!status,'you have taken your investment for this month');
    
    uint256 total = investment[msg.sender];
    uint256 release = 0;
    if (vestStage == uint(VestingStages.TGE) ) {
      release = calculatePercent(5,total) ;
    }else if (vestStage == uint(VestingStages.M12) ) {
      release = calculatePercent(35,total) ;
    } else{
        release = calculatePercent(20,total) ;
    }
   

    require(updateVestingDetails(vestStage,msg.sender,true),'could not update investor details');
    
    require(_token.transfer(msg.sender, release),'could not make transfers at this time');
    
    emit LogVestingWithdrawal(msg.sender, release);
    return true;
  } 
  
}

