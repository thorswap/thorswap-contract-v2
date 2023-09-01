// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {Owners} from "./Owners.sol";

contract TSLedgerAdapter is Owners, ReentrancyGuard {
    struct AggregatorConfig {
        address aggregator;
        uint16 interfaceId;
    }

    mapping(uint16 => AggregatorConfig) public aggregatorConfigs;

    constructor() {
        _setOwner(msg.sender, true);
    }

    function revokeOwnership() external isOwner {
        _setOwner(msg.sender, false);
    }

    // aggregator configs should be restriced to allowed contracts
    // after initial setup to copy current whitelist
    // ownership will be transfered to a multisig controlled by multiple parties
    function setAggregatorConfig(
        uint16 id,
        address aggregator,
        uint16 interfaceId
    ) external isOwner {
        require(interfaceId > 0 && interfaceId < 6, "Invalid interfaceId");
        aggregatorConfigs[id] = AggregatorConfig(aggregator, interfaceId);
    }

    // to help maintainers of this contract
    function getConfig(
        uint16 id
    ) public view returns (address aggregator, uint16 interfaceId) {
        AggregatorConfig memory config = aggregatorConfigs[id];
        return (config.aggregator, config.interfaceId);
    }

    // in case users send tokens to this contract rather than calling it
    function emergencyWithdrawToken(
        address payable to,
        address token,
        uint256 amount
    ) external isOwner {
        SafeTransferLib.safeTransfer(token, to, amount);
    }

    // in case users send gas assets to this contract rather than calling it
    function emergencyWithdrawGasAsset(
        address payable to,
        uint256 amount
    ) external isOwner {
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function _executeDelegateCall(
        address target,
        bytes memory data
    ) private returns (bool success, bytes memory result) {
        (success, result) = target.delegatecall(data);
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

        (bool success, bytes memory result) = _executeDelegateCall(
            config.aggregator,
            params
        );

        require(success, string(result)); // target contract error will bubble up
    }
}
