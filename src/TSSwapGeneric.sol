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

    // only in case someone accidentally sends tokens to this contract
    function rescueFunds(address token, uint256 amount, address to) external isOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function swap(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amount,
        address router,
        bytes calldata data,
        bytes calldata fees
    ) public payable nonReentrant {
        require(router != address(tokenTransferProxy), "no calling ttp");

        if (tokenIn == address(0)) {
            // if tokenIn is Ether
            require(msg.value == amount, "Ether amount mismatch");
        } else {
            tokenTransferProxy.transferTokens(
                tokenIn,
                msg.sender,
                address(this),
                amount
            );
            tokenIn.safeApprove(address(router), 0); // USDT quirk
            tokenIn.safeApprove(address(router), amount);
        }

        // call swap contract
        {
            (bool success, ) = router.call(data);
            require(success, "failed to swap");
        }

        uint256 out;
        if (tokenOut == address(0)) {
            // if tokenOut is Ether
            out = address(this).balance - msg.value; // deduct initial sent Ether, if any
        } else {
            out = IERC20(tokenOut).balanceOf(address(this));
        }
        require(out > 0, "no amount out");

        uint256 fee = getFee(out);
        if (tokenOut == address(0)) {
            payable(feeRecipient).transfer(fee);
        } else {
            tokenOut.safeTransfer(feeRecipient, fee);
        }

        (uint256[] memory feePercents, address[] memory feeRecipients) = abi.decode(fees, (uint256[], address[]));
        for (uint256 i = 0; i < feePercents.length; i++) {
            if (tokenOut == address(0)) {
                payable(feeRecipients[i]).transfer((out * feePercents[i]) / 1000);
            } else {
                tokenOut.safeTransfer(feeRecipients[i], (out * feePercents[i]) / 1000);
            }
            fee += (out * feePercents[i]) / 1000;
        }

        // send leftover to recipient
        if (tokenOut == address(0)) {
            payable(recipient).transfer(out - fee);
        } else {
            tokenOut.safeTransfer(recipient, out - fee);
        }
        emit Swap(tokenIn, tokenOut, recipient, amount, out, fee);
    }
}
