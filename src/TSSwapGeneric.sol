// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {TSAggregator} from "./TSAggregator.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {TSAggregatorTokenTransferProxy} from "./TSAggregatorTokenTransferProxy.sol";

contract TSSwapGeneric is TSAggregator {
    using SafeTransferLib for address;

    event Swap(address tokenId, address tokenOut, address recipient, uint256 amount, uint256 out, uint256 fee);

    constructor(address _ttp) TSAggregator(_ttp) {}

    function swap(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amount,
        address router,
        bytes calldata data,
        bytes calldata fees
    ) public nonReentrant {
        require(router != address(tokenTransferProxy), "no calling ttp");
        tokenTransferProxy.transferTokens(tokenIn, msg.sender, address(this), amount);
        tokenIn.safeApprove(address(router), 0); // USDT quirk
        tokenIn.safeApprove(address(router), amount);

        // call swap contract
        {
            (bool success,) = router.call(data);
            require(success, "failed to swap");
        }

        // collect fees
        uint256 out = IERC20(tokenOut).balanceOf(address(this));
        require(out > 0, "no amount out");
        uint256 fee = getFee(out);
        tokenOut.safeTransfer(feeRecipient, fee);
        (uint256[] memory feePercents, address[] memory feeRecipients) = abi.decode(fees, (uint256[], address[]));
        for (uint256 i = 0; i < feePercents.length; i++) {
            tokenOut.safeTransfer(feeRecipients[i], out * feePercents[i] / 10000);
            fee += out * feePercents[i] / 10000;
        }

        // send leftover to recipient
        tokenOut.safeTransfer(recipient, out - fee);
        emit Swap(tokenIn, tokenOut, recipient, amount, out, fee);
    }
}
