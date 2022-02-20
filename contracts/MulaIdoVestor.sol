// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./MulaVestorUtils.sol";

contract MulaIdoVestor is MulaVestorUtils{
  
  mapping(address => mapping(VestingStages=>bool)) public tracker; 
  mapping(address => uint256) public investment; 
 
  event LogVestingWithdrawal(address beneficiary, uint256 amount);
  constructor(){
    
  }
  
  function getInvestment(address beneficiary) public view returns(uint256) {
    return investment[beneficiary];
  }
  function getVestingDetails(uint256 vestStage, address beneficiary) public view returns (uint256,bool){
    uint256 vestDate;
    bool status;
    
    if(uint(VestingStages.M1) == vestStage){
        vestDate =provisionDates[VestingStages.M1];
        status = tracker[beneficiary][VestingStages.M1];
    }
    if(uint(VestingStages.M2) == vestStage){
        vestDate =provisionDates[VestingStages.M2];
        status = tracker[beneficiary][VestingStages.M2];
    }
    if(uint(VestingStages.M3) == vestStage){
        vestDate =provisionDates[VestingStages.M3];
        status = tracker[beneficiary][VestingStages.M3];
    }
    if(uint(VestingStages.M6) == vestStage){
        vestDate =provisionDates[VestingStages.M6];
        status = tracker[beneficiary][VestingStages.M6];
    }
    return (vestDate,status);
  }
  function getVestTracker() public view returns (bool m1,bool m2,bool m3,bool m6){
    address beneficiary = msg.sender;
    m1 = tracker[beneficiary][VestingStages.M1];
    m2 = tracker[beneficiary][VestingStages.M2];
    m3 = tracker[beneficiary][VestingStages.M3];
    m6 = tracker[beneficiary][VestingStages.M6];

    return (m1,m2,m3,m6);
  }
  function recordInvestment(address beneficiary, uint256 newTotal) onlyOperator public returns(bool) {
    uint256 _total = investment[beneficiary];
    investment[beneficiary] = _total + newTotal;
    return true;
  }

  function updateVestingDetails(uint256 vestStage, address beneficiary) public returns (uint256,bool){
    uint256 vestDate;
    bool status;
    
    if(uint(VestingStages.M1) == vestStage){
      tracker[beneficiary][VestingStages.M1] = true;
    }
    if(uint(VestingStages.M2) == vestStage){
      tracker[beneficiary][VestingStages.M2] = true;
    }
    if(uint(VestingStages.M3) == vestStage){
      tracker[beneficiary][VestingStages.M3] = true;
    }
    if(uint(VestingStages.M6) == vestStage){
      tracker[beneficiary][VestingStages.M6] = true;
    }
    return (vestDate,status);
  }

  function withdrawInvestment(uint256 vestStage) public returns(bool success) {
    (
      uint256 vestDate,
      bool status
    ) = getVestingDetails(vestStage,msg.sender);
    require(vestDate <= block.timestamp,'vault still locked');
    require(!status,'you taken your investment for this month');
    uint256 total = investment[msg.sender];
    uint256 twentyPercent = calculatePercent(20,total) ;
    require(_token.transfer(msg.sender, twentyPercent));
    emit LogVestingWithdrawal(msg.sender, twentyPercent);
    return true;
  } 
  
}

