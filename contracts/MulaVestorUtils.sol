// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MulaTokenUtils.sol";

contract MulaVestorUtils is MulaTokenUtils{
  
  enum VestingStages {TGE,M1,M2,M3,M4,M6,M12} 
  IERC20 public _token;
 
  mapping(VestingStages => uint256) provisionDates;
  mapping(address => bool) public investors;  

  constructor()  {
  }


  function updateTokenAddress(IERC20 token) public onlyOwner() returns (bool){
    _token = token;
    return true;
  }
   
 

  function setVestingDates(uint256 firstListingDate) public {
      provisionDates[VestingStages.TGE] =firstListingDate;
      // provisionDates[VestingStages.M1] =firstListingDate + 30 days;
      // provisionDates[VestingStages.M2] =firstListingDate + (2 *30 days);
      // provisionDates[VestingStages.M3] =firstListingDate + (3 *30 days);
      // provisionDates[VestingStages.M4] =firstListingDate + (4 *30 days);
      // provisionDates[VestingStages.M6] =firstListingDate + (6 *30 days);
      // provisionDates[VestingStages.M12] =firstListingDate + (12 *30 days);

      provisionDates[VestingStages.M1] =firstListingDate + 1 days;
      provisionDates[VestingStages.M2] =firstListingDate + (2 *1 days);
      provisionDates[VestingStages.M3] =firstListingDate + (3 *1 days);
      provisionDates[VestingStages.M4] =firstListingDate + (4 *1 days);
      provisionDates[VestingStages.M6] =firstListingDate + (6 *1 days);
      provisionDates[VestingStages.M12] =firstListingDate + (12 *1 days);
  }
  
  function getVestingDates(uint256 vestStage) public view returns (uint256){
    uint256 vestDate; 
    
    if(uint(VestingStages.TGE) == vestStage){ 
        vestDate =provisionDates[VestingStages.TGE];
    }
    if(uint(VestingStages.M1) == vestStage){ 
        vestDate =provisionDates[VestingStages.M1];
    }
    if(uint(VestingStages.M2) == vestStage){
        vestDate =provisionDates[VestingStages.M2]; 
    }
    if(uint(VestingStages.M3) == vestStage){
        vestDate =provisionDates[VestingStages.M3]; 
    }
    if(uint(VestingStages.M4) == vestStage){
        vestDate =provisionDates[VestingStages.M4]; 
    }
    if(uint(VestingStages.M6) == vestStage){
        vestDate =provisionDates[VestingStages.M6]; 
    }
    if(uint(VestingStages.M12) == vestStage){
        vestDate =provisionDates[VestingStages.M12]; 
    }
    return vestDate;
  }

  function isInvestor(address investor) public view returns (bool){
    return investors[investor];
  }
  

  function calculatePercent(uint numerator, uint denominator) internal  pure returns (uint256){
    return (denominator * (numerator * 100) ) /10000;
  }
}
