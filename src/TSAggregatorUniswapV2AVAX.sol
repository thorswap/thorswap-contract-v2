// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { TSAggregator } from "./TSAggregator.sol";
import { IThorchainRouter } from "./interfaces/IThorchainRouter.sol";
import { IUniswapRouterV2AVAX } from "./interfaces/IUniswapRouterV2AVAX.sol";

contract TSAggregatorUniswapV2AVAX is TSAggregator {
    using SafeTransferLib for address;

    address public weth;
    IUniswapRouterV2AVAX public swapRouter;

    event SwapIn(address from, address token, uint256 amount, uint256 out, uint256 fee, address vault, string memo);
    event SwapOut(address to, address token, uint256 amount, uint256 fee);

    constructor(
      address _ttp, address _weth, address _swapRouter
    ) TSAggregator(_ttp) {
        weth = _weth;
        swapRouter = IUniswapRouterV2AVAX(_swapRouter);
    }

    function swapIn(
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
        swapRouter.swapExactTokensForAVAX(
            amount,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        uint out = address(this).balance;
        uint outMinusFee = skimFee(out);
        vault.call{value: outMinusFee}(bytes(memo));
        emit SwapIn(msg.sender, token, amount, out, out-outMinusFee, vault, memo);
    }

    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        uint256 amount = skimFee(msg.value);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        swapRouter.swapExactAVAXForTokens{value: amount}(
            _parseAmountOutMin(amountOutMin),
            path,
            to,
            type(uint).max // deadline
        );
        emit SwapOut(to, token, msg.value, msg.value-amount);
    }
}

