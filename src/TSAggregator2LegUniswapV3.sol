// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";
import { TSAggregator } from "./TSAggregator.sol";
import { IThorchainRouter } from "./interfaces/IThorchainRouter.sol";
import { IUniswapRouterV3 } from "./interfaces/IUniswapRouterV3.sol";

contract TSAggregatorUniswapV3 is TSAggregator {
    using SafeTransferLib for address;

    IWETH9 public weth;
    uint24 public poolFee;
    IUniswapRouterV3 public swapRouter;
    address public legToken;
    uint24 public legPoolFee;

    constructor(uint24 _poolFee, address _weth, address _swapRouter, address _legToken, uint24 _legPoolFee) {
        weth = IWETH9(_weth);
        poolFee = _poolFee;
        swapRouter = IUniswapRouterV3(_swapRouter);
        legToken = _legToken;
        legPoolFee = _legPoolFee;
    }

    function swapIn(
        address tcRouter,
        address tcVault,
        string calldata tcMemo,
        address token,
        uint amount,
        uint amountOutMin,
        uint deadline
    ) public nonReentrant {
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeApprove(address(swapRouter), amount);

        bytes memory path = abi.encodePacked(token, poolFee, legToken, legPoolFee, address(weth));
        uint amountOut = swapRouter.exactInput(IUniswapRouterV3.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: deadline,
            amountIn: amount,
            amountOutMinimum: amountOutMin
        }));
        weth.withdraw(amountOut);

        amountOut = skimFee(amountOut);
        IThorchainRouter(tcRouter).depositWithExpiry{value: amountOut}(
            payable(tcVault),
            address(0), // ETH
            amountOut,
            tcMemo,
            deadline
        );
    }

    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        uint256 amount = skimFee(msg.value);
        bytes memory path = abi.encodePacked(address(weth), legPoolFee, legToken, poolFee, token);
        weth.deposit{value: amount}();
        swapRouter.exactInput(IUniswapRouterV3.ExactInputParams({
            path: path,
            recipient: to,
            deadline: type(uint).max,
            amountIn: amount,
            amountOutMinimum: amountOutMin
        }));
    }
}
