// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";
import { Owners } from "./Owners.sol";

contract TSLedgerAdapter is Owners, ReentrancyGuard {
    
    struct AggregatorConfig {
        address aggregator;
        uint16 interfaceId;
    }

    mapping(uint16 => AggregatorConfig) public aggregatorConfigs;

    constructor() {
        _setOwner(msg.sender, true);
    }

    function addOwner(address owner) external isOwner {
        _setOwner(owner, true);
    }

    function removeOwner(address owner) external isOwner {
        _setOwner(owner, false);
    }

    function revokeOwnership() external isOwner {
        _setOwner(msg.sender, false);
    }

    // aggregator configs should be restriced to allowed contracts
    // after initial setup to copy current whitelist
    // ownership will be transfered to a multisig controlled by multiple parties
    function setAggregatorConfig(uint16 id, address aggregator, uint16 interfaceId) external isOwner {
        require(interfaceId > 0 && interfaceId < 6, "Invalid interfaceId");
        aggregatorConfigs[id] = AggregatorConfig(aggregator, interfaceId);
    }

    // to help maintainers of this contract
    function getConfig(uint16 id) public view returns (address aggregator, uint16 interfaceId) {
        AggregatorConfig memory config = aggregatorConfigs[id];
        return (config.aggregator, config.interfaceId);
    }

    // in case users send tokens to this contract rather than calling it
    function emergencyWithdrawToken(address payable to, address token, uint256 amount) external isOwner {
        SafeTransferLib.safeTransfer(token, to, amount);
    }

    // in case users send gas assets to this contract rather than calling it
    function emergencyWithdrawGasAsset(address payable to, uint256 amount) external isOwner {
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function _depositWithExpiry(address target, bytes calldata params) private returns (bool success) {
        (address payable vault, address asset, uint amount, string memory memo, uint expiration) = abi.decode(params, (address, address, uint, string, uint));
        (success,) = target.call{value: msg.value}(abi.encodeWithSignature("depositWithExpiry(address,address,uint256,string,uint256)", vault, asset, amount, memo, expiration));
        return success;
    }

    function _tcGenericSwapIn(address target, bytes calldata params) private returns (bool success) {
        (address tcRouter, address tcVault, string memory tcMemo, address token, uint amount, address router, bytes memory data, uint deadline) = abi.decode(params, (address, address, string, address, uint, address, bytes, uint));
        (success,) = target.call{value: msg.value}(abi.encodeWithSignature("swapIn(address,address,string,address,uint256,address,bytes,uint256)", tcRouter, tcVault, tcMemo, token, amount, router, data, deadline));
        return success;
    }

    function _tcDexSwapIn(address target, bytes calldata params) private returns (bool success) {
        (address tcRouter, address tcVault, string memory tcMemo, address token, uint amount, uint amountOutMin, uint deadline) = abi.decode(params, (address, address, string, address, uint, uint, uint));
        (success,) = target.call{value: msg.value}(abi.encodeWithSignature("swapIn(address,address,string,address,uint256,uint256,uint256)", tcRouter, tcVault, tcMemo, token, amount, amountOutMin, deadline));
        return success;
    }

    function _dexSwapIn(address target, bytes calldata params) private returns (bool success) {
        (address router, address vault, string memory memo, address token, uint amount, uint amountOutMin, uint deadline) = abi.decode(params, (address, address, string, address, uint, uint, uint));
        (success,) = target.call{value: msg.value}(abi.encodeWithSignature("swapIn(address,address,string,address,uint256,uint256,uint256)", router, vault, memo, token, amount, amountOutMin, deadline));
        return success;
    }

    function _swap(address target, bytes calldata params) private returns (bool success) {
        (address router, address vault, string memory memo, address tokenIn, address tokenOut, uint amountIn, uint amountOutMin, uint deadline) = abi.decode(params, (address, address, string, address, address, uint, uint, uint));
        (success,) = target.call{value: msg.value}(abi.encodeWithSignature("swap(address,address,string,address,address,uint256,uint256,uint256)", router, vault, memo, tokenIn, tokenOut, amountIn, amountOutMin, deadline));
        return success;
    }

    function ledgerCall(
        uint16 aggregatorConfig,
        bytes calldata params,
        string calldata memo,
        string calldata sellAsset,
        uint256 sellAmount,
        string calldata buyAsset,
        uint256 buyAmountExpected,
        uint256 buyAmountMin
    ) external payable nonReentrant {
        AggregatorConfig memory config = aggregatorConfigs[aggregatorConfig];
        require(config.aggregator != address(0), "Aggregator must be set.");
        bool success;

        if(config.interfaceId == 1) {
            success = _depositWithExpiry(config.aggregator, params);
        } else if(config.interfaceId == 2) {
            success = _tcGenericSwapIn(config.aggregator, params);
        } else if(config.interfaceId == 3) {
            success = _tcDexSwapIn(config.aggregator, params);
        } else if(config.interfaceId == 4) {
            success = _dexSwapIn(config.aggregator, params);
        } else if(config.interfaceId == 5) {
            success = _swap(config.aggregator, params);
        } else {
            revert("Invalid interfaceId");
        }

        require(success, "External call failed.");
    }
}
