// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ERC20 } from "../../lib/ERC20.sol";

contract TestERC20 is ERC20 {
  constructor() ERC20("Test Token", "TTKN", 18) {
  }

  function mintTo(address to, uint amount) public {
      _mint(to, amount);
  }
}
