// SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9.0;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MulaVestorUtils  is Ownable{
  
  enum VestingStages {TGE,M1,M2,M3,M4,M6,M12} 
  IERC20 public immutable _token;
  address public _saleContract;
  bool public isSaleContractSet;
  bool public isFirstListingDateSet;

  mapping(VestingStages => uint256) public provisionDates;
  mapping(address => bool)  public investors;

  event LogVestingWithdrawal(address indexed beneficiary, uint256 indexed amount);
  event LogVestingRecord(address indexed beneficiary, uint256 indexed amount);
  modifier onlySaleContract() {
      require(msg.sender==_saleContract,"you are not permitted to make transactions, only sale contract");
      _;
  }
  constructor(IERC20 token)Ownable()  {
    _token = token;
  }

  function setVestingDates(uint256 firstListingDate) public  onlySaleContract{
    
      require(!isFirstListingDateSet,'First listing date has already been set.');
      //update isfirstlistingdate
      isFirstListingDateSet=true; 
      
      // live
      provisionDates[VestingStages.TGE] =firstListingDate; 
      provisionDates[VestingStages.M1] =firstListingDate + 30 days;
      provisionDates[VestingStages.M2] =firstListingDate + (2 *30 days);
      provisionDates[VestingStages.M3] =firstListingDate + (3 *30 days);
      provisionDates[VestingStages.M4] =firstListingDate + (4 *30 days);
      provisionDates[VestingStages.M6] =firstListingDate + (6 *30 days);
      provisionDates[VestingStages.M12] =firstListingDate + (12 *30 days);

      // TEST 
      // provisionDates[VestingStages.M1] =firstListingDate + 1 days;
      // provisionDates[VestingStages.M2] =firstListingDate + (2 *1 days);
      // provisionDates[VestingStages.M3] =firstListingDate + (3 *1 days);
      // provisionDates[VestingStages.M4] =firstListingDate + (4 *1 days);
      // provisionDates[VestingStages.M6] =firstListingDate + (6 *1 days);
      // provisionDates[VestingStages.M12] =firstListingDate + (12 *1 days);
  }
  
  function getVestingDates(VestingStages vestStage) public view returns (uint256){
    uint256 vestDate = provisionDates[vestStage]; 
    return vestDate;
  }

 /**white list address to be able to transact during crowdsale. **/
  function setSaleContract(address saleContract) onlyOwner() public { 
    require(!isSaleContractSet,"Sale contract set already");
    _saleContract = saleContract;
    isSaleContractSet =true;
  }

  function calculatePercent(uint numerator, uint denominator) internal  pure returns (uint256){
    return (denominator * (numerator * 100) ) /10000;
  }
}
