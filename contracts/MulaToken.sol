// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MulaToken is ERC20{
  uint256 tSupply = 200 * 10**6 * (10 ** uint256(decimals()));

  constructor() ERC20("Mula", "MULA"){
      _mint(msg.sender, tSupply);
  }

}