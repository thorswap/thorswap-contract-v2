// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { TSAggregator } from "./TSAggregator.sol";
import { IThorchainRouter } from "./interfaces/IThorchainRouter.sol";
import { IUniswapRouterV2 } from "./interfaces/IUniswapRouterV2extended.sol";
import { Owners } from "./Owners.sol";

contract TSAggregatorUniswapV2 is Owners, TSAggregator {
    using SafeTransferLib for address;

    address public weth;
    IUniswapRouterV2 public swapRouter;

    mapping(address => bool) public tokensWithTransferFee;

    event SwapIn(address from, address token, uint256 amount, uint256 out, uint256 fee, address vault, string memo);
    event SwapOut(address to, address token, uint256 amount, uint256 fee);

    constructor(
      address _ttp, address _weth, address _swapRouter
    ) TSAggregator(_ttp) {
        weth = _weth;
        swapRouter = IUniswapRouterV2(_swapRouter);
        _setOwner(msg.sender, true);
    }

    function addTokenWithTransferFee(address token) external isOwner {
        tokensWithTransferFee[token] = true;
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

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;

        if(tokensWithTransferFee[token]) {
            swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                amountOutMin,
                path,
                address(this),
                deadline
            );
        } else {
            swapRouter.swapExactTokensForETH(
                amount,
                amountOutMin,
                path,
                address(this),
                deadline
            );
        }

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
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        if(tokensWithTransferFee[token]) {
            swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                _parseAmountOutMin(amountOutMin),
                path,
                to,
                type(uint).max // deadline
            );
        } else {
            swapRouter.swapExactETHForTokens{value: amount}(
                _parseAmountOutMin(amountOutMin),
                path,
                to,
                type(uint).max // deadline
            );
        }

        emit SwapOut(to, token, msg.value, msg.value-amount);
    }
}

