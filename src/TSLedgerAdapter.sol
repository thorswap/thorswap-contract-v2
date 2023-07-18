// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";
import { Owners } from "./Owners.sol";

contract TSLedgerAdapter is Owners, ReentrancyGuard {
    using SafeTransferLib for address;

    struct AggregatorConfig {
        address aggregator;
        string functionSignature;
    }

    mapping(uint16 => AggregatorConfig) public aggregatorConfigs;

    event TSLedgerCall(address from, uint16 aggregatorConfig, string, memo, string sellAsset, string sellAmount, string buyAsset, string buyAmountExpected);

    constructor() {
        _setOwner(msg.sender, true);
    }

    function addOwner(address owner, bool isOwner) external isOwner {
        _setOwner(owner, isOwner);
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
        return _getAggregatorConfig(id);
    }

    function _getAggregatorConfig(uint16 id) internal view returns (address aggregator, string memory functionSignature) {
        AggregatorConfig storage config = aggregatorConfigs[id];
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
        (address aggregator, string memory functionSignature) = _getAggregatorConfig(aggregatorConfig);
        bytes memory data = abi.encodeWithSignature(functionSignature, params);
        _proxyCall(aggregator, data);
    }
}