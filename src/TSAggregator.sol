// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";
import { Owners } from "./Owners.sol";

abstract contract TSAggregator is Owners, ReentrancyGuard {
    using SafeTransferLib for address;

    event FeeUpdated(uint256 fee, address feeRecipient);

    uint256 public fee;
    address public feeRecipient;

    constructor() {
        _setOwner(msg.sender, true);
    }

    // Needed for the swap router to be able to send back ETH
    receive() external payable {}

    function updateFee(uint256 _fee, address _feeRecipient) public isOwner {
        fee = _fee;
        feeRecipient = _feeRecipient;
        emit FeeUpdated(_fee, _feeRecipient);
    }

    function skimFee(uint256 amount) internal returns (uint256) {
        if (fee != 0 && feeRecipient != address(0)) {
            uint256 feeAmount = (amount * fee) / 10000;
            feeRecipient.safeTransferETH(feeAmount);
            amount -= feeAmount;
        }
        return amount;
    }
}
