// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ERC20 } from "../lib/ERC20.sol";
import { SafeTransferLib } from "../lib/SafeTransferLib.sol";

contract vTHOR is ERC20 {
    using SafeTransferLib for address;

    address public token;

    constructor(address _token) ERC20("V THORSwap", "vTHOR", 18) {
        token = _token;
    }

    function deposit(uint256 amount) public {
        uint256 totalShares = totalSupply;
        uint256 totalDeposits = ERC20(token).balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        if (totalShares == 0 || totalDeposits == 0) {
            _mint(msg.sender, amount);
        } else {
            _mint(msg.sender, (amount * totalShares) / totalDeposits);
        }
    }

    function withdraw(uint256 share) public {
        uint256 totalShares = totalSupply;
        uint256 totalDeposits = ERC20(token).balanceOf(address(this));
        uint256 amount = (share * totalDeposits) / totalShares;
        _burn(msg.sender, share);
        token.safeTransfer(msg.sender, amount);
    }
}
