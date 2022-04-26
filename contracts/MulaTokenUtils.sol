// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
contract MulaTokenUtils is Ownable{
  
  mapping(address=>bool)operators;
  /** If false we are are in transfer lock up period.*/
  bool public released = false;
  
  /** MODIFIER: Limits token transfer until the lockup period is over.*/
    modifier canTransfer() {
        if(!released) {
            require(operators[msg.sender],"you are not permitted to make transactions, not an operator");
        }
        _;
    }
   modifier onlyOperator() {
        require(operators[msg.sender],"you are not permitted to make transactions, not an operator");
        _;
    }



  constructor() Ownable()  {
  }

  /**white lsit address to be able to transact during crowdsale. **/
  function whitelistOperator(address _operator) onlyOwner() public { 
      operators[_operator] = true;
  }
  function isOperator(address _add) public view returns(bool) { 
      if(operators[_add]){
          return true;
      }
      return false;
  }

  /** Allows only the owner to relase the tokens into the wild */
  function releaseToken() onlyOwner() public {
          released = true;       
  }
  
}
