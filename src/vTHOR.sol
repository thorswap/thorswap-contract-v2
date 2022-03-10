// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ERC20Vote } from "../lib/ERC20Vote.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";

contract vTHOR is ERC20Vote, ReentrancyGuard {
    using SafeTransferLib for address;

    address public token;

    constructor(address _token) ERC20Vote("vTHOR", "vTHOR", 18) {
        token = _token;
    }

    function deposit(uint256 amount) public nonReentrant {
        uint256 totalShares = totalSupply;
        uint256 totalDeposits = IERC20(token).balanceOf(address(this));
        if (totalShares == 0 || totalDeposits == 0) {
            _mint(msg.sender, amount);
        } else {
            _mint(msg.sender, (amount * totalShares) / totalDeposits);
        }
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 share) public nonReentrant {
        uint256 totalShares = totalSupply;
        uint256 totalDeposits = IERC20(token).balanceOf(address(this));
        uint256 amount = (share * totalDeposits) / totalShares;
        _burn(msg.sender, share);
        token.safeTransfer(msg.sender, amount);
    }
}
