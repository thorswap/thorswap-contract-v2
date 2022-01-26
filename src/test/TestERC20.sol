// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ERC20 } from "../../lib/ERC20.sol";
import { Vm } from "../../lib/Vm.sol";
import { IWETH9 } from "../interfaces/IWETH9.sol";

contract TestERC20 is ERC20, IWETH9 {
  Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  constructor() ERC20("Test Token", "TTKN", 18) {
  }

  function mintTo(address to, uint amount) public {
      _mint(to, amount);
  }

  function deposit() external override payable {
      _mint(msg.sender, msg.value);
  }

  function withdraw(uint amount) external override {
      _burn(msg.sender, amount);
      vm.deal(msg.sender, amount);
  }
}
