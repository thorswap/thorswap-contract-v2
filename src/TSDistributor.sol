// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20 } from './interfaces/IERC20.sol';
import { Owners } from "./Owners.sol";

contract TSDistributor is Owners {
    address public walletA;
    address public walletB;
    uint16 public shareA;
    uint16 public shareB;

    event AssetDistributed(address indexed asset, uint256 amountA, uint256 amountB);

    constructor() {
        _setOwner(msg.sender, true);
    }

    function setWalletPair(address _walletA, address _walletB, uint16 _shareA, uint16 _shareB) public isOwner {
        require(_shareA + _shareB == 10000, "Shares must total 100%");
        walletA = _walletA;
        walletB = _walletB;
        shareA = _shareA;
        shareB = _shareB;
    }

    function distribute(address asset) public {
        require(walletA != address(0) && walletB != address(0), "Wallet pair not set");
        uint256 balance;

        if(asset == address(0)) {
            balance = address(this).balance;
            require(balance > 0, "No assets to distribute");

            (bool successA, ) = payable(walletA).call{value: balance * shareA / 10000}("");
            require(successA, "Transfer to walletA failed");
            (bool successB, ) = payable(walletB).call{value: balance * shareB / 10000}("");
            require(successB, "Transfer to walletB failed");
        } else {
            balance = IERC20(asset).balanceOf(address(this));
            require(balance > 0, "No assets to distribute");

            uint256 amountA = balance * shareA / 10000;
            uint256 amountB = balance * shareB / 10000;

            require(IERC20(asset).transfer(walletA, amountA), "Transfer to walletA failed");
            require(IERC20(asset).transfer(walletB, amountB), "Transfer to walletB failed");
        }

        emit AssetDistributed(asset, balance * shareA / 10000, balance * shareB / 10000);
    }
    
    function setOwner(address newOwner) public isOwner {
        _setOwner(newOwner, true);
    }

    // Function to receive Ether
    receive() external payable {}

    // Function to allow contract to accept Ether
    fallback() external payable {}
}