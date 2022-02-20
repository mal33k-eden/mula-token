// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MulaVestorUtils is Ownable{
  
  enum VestingStages {M1,M2,M3,M4,M6,M12} 
  IERC20 public _token;
  address _operator;
  modifier onlyOperator {
    require(msg.sender == _operator, "You can not use this vault");
    _;
  }
  mapping(VestingStages => uint256) provisionDates; 

  constructor()Ownable() {
  }


  function updateTokenAddress(IERC20 token) public onlyOwner() returns (bool){
    _token = token;
    return true;
  }
  function getOperator() public view returns (address){
    return _operator;
  }

  function setOperator(address operator) public onlyOwner() returns (bool){
    _operator = operator;
    return true;
  }

  function updateVestingDates(uint256 firstListingDate) public {
      provisionDates[VestingStages.M1] =firstListingDate + 30 days;
      provisionDates[VestingStages.M2] =firstListingDate + (2 *30 days);
      provisionDates[VestingStages.M3] =firstListingDate + (3 *30 days);
      provisionDates[VestingStages.M4] =firstListingDate + (4 *30 days);
      provisionDates[VestingStages.M6] =firstListingDate + (6 *30 days);
      provisionDates[VestingStages.M12] =firstListingDate + (12 *30 days);
  }

  function calculatePercent(uint numerator, uint denominator) internal  pure returns (uint256){
    return (denominator * (numerator * 100) ) /10000;
  }
}
