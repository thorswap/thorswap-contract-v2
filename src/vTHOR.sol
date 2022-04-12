// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ERC20Vote } from "../lib/ERC20Vote.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";

contract vTHOR is ERC20Vote, ReentrancyGuard {
    using SafeTransferLib for address;
    using FixedPointMathLib for uint256;

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    IERC20 public asset;

    constructor(IERC20 _asset) ERC20Vote("vTHOR", "vTHOR", 18) {
        asset = _asset;
    }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    function maxDeposit(address) public view returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf[owner];
    }

    /*
    function deposit(uint256 amount) public nonReentrant {
        uint256 totalShares = totalSupply;
        uint256 totalDeposits = IERC20(asset).balanceOf(address(this));
        if (totalShares == 0 || totalDeposits == 0) {
            _mint(msg.sender, amount);
        } else {
            _mint(msg.sender, (amount * totalShares) / totalDeposits);
        }
        address(asset).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 share) public nonReentrant {
        uint256 totalShares = totalSupply;
        uint256 totalDeposits = IERC20(asset).balanceOf(address(this));
        uint256 amount = (share * totalDeposits) / totalShares;
        _burn(msg.sender, share);
        address(asset).safeTransfer(msg.sender, amount);
    }
    */

    function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        // Need to transfer before minting or ERC777s could reenter.
        address(asset).safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.
        // Need to transfer before minting or ERC777s could reenter.
        address(asset).safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }
        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        address(asset).safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }
        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");
        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        address(asset).safeTransfer(receiver, assets);
    }
}
