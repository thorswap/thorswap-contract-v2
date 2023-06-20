// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { TSAggregator } from "./TSAggregator.sol";
import { IThorchainRouter } from "./interfaces/IThorchainRouter.sol";

interface IWoofi {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        address rebateTo
    ) external payable;
}

contract TSAggregatorWoofi is TSAggregator {
    using SafeTransferLib for address;

    address public weth;
    IWoofi public swapRouter;

    event SwapIn(address from, address token, uint256 amount, uint256 out, uint256 fee, address vault, string memo);
    event SwapOut(address to, address token, uint256 amount, uint256 fee);

    constructor(
      address _ttp, address _weth, address _swapRouter
    ) TSAggregator(_ttp) {
        weth = _weth;
        swapRouter = IWoofi(_swapRouter);
    }

    function swapIn(
        address router,
        address vault,
        string calldata memo,
        address token,
        uint amount,
        uint amountOutMin,
        uint deadline
    ) public nonReentrant {
        tokenTransferProxy.transferTokens(token, msg.sender, address(this), amount);
        token.safeApprove(address(swapRouter), 0); // USDT quirk
        token.safeApprove(address(swapRouter), amount);

        swapRouter.swap(
            token,
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            amount,
            amountOutMin,
            payable(address(this)),
            address(0)
        );

        uint256 out = address(this).balance;
        {
            uint256 outMinusFee = skimFee(out);
            IThorchainRouter(router).depositWithExpiry{value: outMinusFee}(
                payable(vault),
                address(0),
                outMinusFee,
                memo,
                deadline
            );
        }
        emit SwapIn(msg.sender, token, amount, out+getFee(out), getFee(out), vault, memo);
    }

    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        uint256 amount = skimFee(msg.value);
        swapRouter.swap{value: amount}(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            token,
            amount,
            _parseAmountOutMin(amountOutMin),
            payable(to),
            address(0)
        );
        emit SwapOut(to, token, msg.value, msg.value-amount);
    }
}

