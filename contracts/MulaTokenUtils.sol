// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
contract MulaTokenUtils is Ownable{
  
  mapping(address=>bool) private operators;
  /** If false we are are in transfer lock up period.*/
  bool public released = false;
  
  /** MODIFIER: Limits token transfer until the lockup period is over.*/
  modifier canTransfer() {
    if(!released) {
        require(isOperator(msg.sender),"Only operators can transfer at this time");
    }
    _;
  }
  modifier onlyOperator() {
    require(isOperator(msg.sender),"You are not permitted to make transactions, not an operator");
    _;
  }

  constructor() Ownable()  {
  }
  /**white list address to be able to transact during crowdsale. **/
  function whitelistOperator(address _operator, bool _status) onlyOwner() public { 
    operators[_operator] = _status;
  }
  function isOperator(address _add) public view returns(bool) { 
    return operators[_add];
  }

  /** Allows only the owner to update  tokens release into the wild */
  function updateRelease() onlyOwner() public {
    require(!released, "Once contract has been marked as released, it can not be reversed.");
    released = true;       
  }
  function isRelease() public view returns(bool){
      return released;
  }
  
}
