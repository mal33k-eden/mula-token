// SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MulaTokenUtils.sol";
contract MulaToken is ERC20, MulaTokenUtils{
  
  uint256 private constant tSupply = 200 * 10**6 * (10 ** 18);

  constructor() ERC20("Mula Token", "MULA"){
    _mint(msg.sender, tSupply);
  }

  function transfer(address _to, uint256 _value) canTransfer()  public virtual override  returns (bool success) {
    super.transfer(_to,_value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) canTransfer() public virtual override returns (bool success) {
    super.transferFrom(_from, _to, _value);
    return true;
  }

}