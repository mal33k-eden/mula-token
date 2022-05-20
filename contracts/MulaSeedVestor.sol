// SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9.0;

import "./MulaVestorUtils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract MulaSeedVestor is MulaVestorUtils{
  using SafeMath for uint256;
  mapping(address => mapping(VestingStages=>bool)) public tracker; 
  mapping(address => uint256) public totalInvestment; 
  mapping(address => mapping(VestingStages => uint256)) public vestedInvestment;
  
  constructor(IERC20 token)MulaVestorUtils(token){
    
  }
  
  function getInvestmentTotal(address beneficiary) public view returns(uint256) {
    return totalInvestment[beneficiary];
  }
  function getVestingStageInvestment(address beneficiary,VestingStages vestStage) public view returns(uint256) {
    return vestedInvestment[beneficiary][vestStage];
  }
  function getVestingDetails(VestingStages vestStage, address beneficiary) public view returns (uint256,bool){
    uint256 vestDate;
    bool status;
    vestDate =provisionDates[vestStage];
    status   = tracker[beneficiary][vestStage];
    return (vestDate,status);
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
  function recordInvestment(address beneficiary, uint256 newTotal) onlySaleContract public returns(bool) {
    require(!isFirstListingDateSet, "you can not make any investments at this time.");

    //get 5% of investments
    uint256 fivePercent = calculatePercent(5,newTotal);
    //get 35% of investments
    uint256 thirtyFivePercent = calculatePercent(35,newTotal);
    //get 20% of investments
    uint256 twentyPercent = calculatePercent(20,newTotal);
    
    //record tge funds
    uint256 tgeFunds = vestedInvestment[beneficiary][VestingStages.TGE];
    vestedInvestment[beneficiary][VestingStages.TGE]=fivePercent.add(tgeFunds);
    
    //records m2 funds
    uint256 m2Funds  = vestedInvestment[beneficiary][VestingStages.M2];
    vestedInvestment[beneficiary][VestingStages.M2]=twentyPercent.add(m2Funds);
    
    //records m3 funds
    uint256 m3Funds  = vestedInvestment[beneficiary][VestingStages.M3];
    vestedInvestment[beneficiary][VestingStages.M3]=twentyPercent.add(m3Funds);
    
    //records m4 funds
    uint256 m4Funds  = vestedInvestment[beneficiary][VestingStages.M4];
    vestedInvestment[beneficiary][VestingStages.M4]=twentyPercent.add(m4Funds);

    //records m12 funds
    uint256 m12Funds  = vestedInvestment[beneficiary][VestingStages.M12];
    vestedInvestment[beneficiary][VestingStages.M12]=thirtyFivePercent.add(m12Funds);
    
    investors[beneficiary]= true;

    uint256 _oldTotal = totalInvestment[beneficiary];
    totalInvestment[beneficiary] =_oldTotal.add(newTotal);

    emit LogVestingRecord(beneficiary, newTotal);
    return true;
  }

  function updateVestingDetails(VestingStages vestStage, address beneficiary,bool status) internal returns (bool){
    tracker[beneficiary][vestStage] = status;
    return true;
  }

  function withdrawInvestment(VestingStages vestStage) public returns(bool success) {
    
    require(isFirstListingDateSet, "first listing date has to be set before withdrawls");
    require(investors[msg.sender], 'Sorry! you are not an investor.');
    (
      uint256 vestDate,
      bool status
    ) = getVestingDetails(vestStage,msg.sender);
    require(vestDate != 0, 'Invalid vesting stage');
    require(vestDate <= block.timestamp,'vault still locked');
    require(!status,'you have taken your investment for this month');
    
    uint256 amount = vestedInvestment[msg.sender][vestStage];

    require(updateVestingDetails(vestStage,msg.sender,true),'could not update investor details');
    
    require(_token.transfer(msg.sender, amount),'could not make transfers at this time');
    
    emit LogVestingWithdrawal(msg.sender, amount);
    return true;
  } 
  
}

