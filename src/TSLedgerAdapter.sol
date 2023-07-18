// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";
import { Owners } from "./Owners.sol";

contract TSLedgerAdapter is Owners, ReentrancyGuard {
    
    struct AggregatorConfig {
        address aggregator;
        string functionSignature;
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
    function setAggregatorConfig(uint16 id, address aggregator, string calldata functionSignature) external isOwner {
        aggregatorConfigs[id] = AggregatorConfig(aggregator, functionSignature);
    }

    function getConfig(uint16 id) public view returns (address aggregator, string memory functionSignature) {
        AggregatorConfig memory config = aggregatorConfigs[id];
        require(config.aggregator != address(0), "AggregatorConfig not set");

        aggregator = config.aggregator;
        functionSignature = config.functionSignature;

        return (aggregator, functionSignature);
    }

    function _proxyCall(address aggregator, bytes memory data) internal {
        (bool success, bytes memory returnData) = aggregator.delegatecall(data);
        require(success, string(returnData));
    }

    function ledgerCall(
        uint16 aggregatorConfig,
        bytes calldata params,
        string calldata memo,
        string calldata sellAsset,
        string calldata sellAmount,
        string calldata buyAsset,
        string calldata buyAmountExpected,
        string calldata buyAmountMin
    ) external nonReentrant {
        AggregatorConfig memory config = aggregatorConfigs[aggregatorConfig];
        require(config.aggregator != address(0), "AggregatorConfig not set");

        bytes memory data = abi.encodeWithSignature(config.functionSignature, params);
        _proxyCall(config.aggregator, data);
    }
}