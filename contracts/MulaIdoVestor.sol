// SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MulaVestorUtils.sol";

contract MulaIdoVestor is MulaVestorUtils{
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
  function getVestTracker() public view returns (bool tge,bool m1,bool m2,bool m3,bool m6){
    address beneficiary = msg.sender;
    tge = tracker[beneficiary][VestingStages.TGE];
    m1  = tracker[beneficiary][VestingStages.M1];
    m2  = tracker[beneficiary][VestingStages.M2];
    m3  = tracker[beneficiary][VestingStages.M3];
    m6  = tracker[beneficiary][VestingStages.M6];

    return (tge,m1,m2,m3,m6);
  }
  function recordInvestment(address beneficiary, uint256 newTotal) onlySaleContract public returns(bool) {
    require(!isFirstListingDateSet, "you can not make any investments at this time.");
    
    //get 20% of investments
    uint256 twentyPercent = calculatePercent(20,newTotal);
    
    //record tge funds
    uint256 tgeFunds = vestedInvestment[beneficiary][VestingStages.TGE];
    vestedInvestment[beneficiary][VestingStages.TGE]=twentyPercent.add(tgeFunds);
    
    //records m1 funds
    uint256 m1Funds  = vestedInvestment[beneficiary][VestingStages.M1];
    vestedInvestment[beneficiary][VestingStages.M1]=twentyPercent.add(m1Funds);
    
    //records m2 funds
    uint256 m2Funds  = vestedInvestment[beneficiary][VestingStages.M2];
    vestedInvestment[beneficiary][VestingStages.M2]=twentyPercent.add(m2Funds);
    
    //records m3 funds
    uint256 m3Funds  = vestedInvestment[beneficiary][VestingStages.M3];
    vestedInvestment[beneficiary][VestingStages.M3]=twentyPercent.add(m3Funds);
    
    //records m6 funds
    uint256 m6Funds  = vestedInvestment[beneficiary][VestingStages.M6];
    vestedInvestment[beneficiary][VestingStages.M6]=twentyPercent.add(m6Funds);
    
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

